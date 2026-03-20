#!/usr/bin/env python3
"""
Sync bootstrap deployment wiring into a GitHub Environment.

Documented v1 usage:
    python scripts/sync_github_env.py dev

This helper is intentionally limited to deployment wiring only.
It does NOT manage Terraform desired-state inputs such as TF_VAR_* values.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path


REQUIRED_OUTPUTS = {
    "AWS_ROLE_TO_ASSUME": "github_actions_role_arn",
    "AWS_REGION": "aws_region",
    "TF_BACKEND_BUCKET": "tf_state_bucket_name",
    "TF_BACKEND_KEY": "tf_backend_key",
}


def fail(message: str) -> None:
    print(f"Error: {message}", file=sys.stderr)
    raise SystemExit(1)


def find_executable(*names: str) -> str:
    for name in names:
        path = shutil.which(name)
        if path:
            return path
    fail(f"Required executable not found: {', '.join(names)}")


def format_command_error(prefix: str, result: subprocess.CompletedProcess[str]) -> str:
    stderr = (result.stderr or "").strip()
    stdout = (result.stdout or "").strip()

    details = stderr or stdout
    if details:
        return f"{prefix} {details}"
    return prefix


def run_command(
    args: list[str],
    *,
    cwd: Path | None = None,
    capture_output: bool = True,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,
        cwd=str(cwd) if cwd else None,
        check=False,
        text=True,
        capture_output=capture_output,
    )


def normalize_repo_url(remote_url: str) -> str:
    remote_url = remote_url.strip()

    ssh_match = re.match(r"git@github\.com:(?P<repo>.+?)(?:\.git)?$", remote_url)
    if ssh_match:
        return ssh_match.group("repo")

    https_match = re.match(r"https://github\.com/(?P<repo>.+?)(?:\.git)?$", remote_url)
    if https_match:
        return https_match.group("repo")

    fail(f"Unsupported remote.origin.url format: {remote_url}")


def get_repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def ensure_repo_root(git_bin: str, repo_root: Path) -> None:
    result = run_command([git_bin, "rev-parse", "--show-toplevel"], cwd=repo_root)
    if result.returncode != 0:
        fail(format_command_error("Could not determine git repository root.", result))

    actual_root = Path(result.stdout.strip()).resolve()
    if actual_root != repo_root.resolve():
        fail(
            f"Script-derived repo root does not match git top-level. "
            f"script={repo_root}, git={actual_root}"
        )


def get_current_repo(git_bin: str, gh_bin: str, repo_root: Path) -> str:
    git_result = run_command(
        [git_bin, "config", "--get", "remote.origin.url"],
        cwd=repo_root,
    )
    if git_result.returncode != 0 or not git_result.stdout.strip():
        fail(format_command_error("Could not read git remote.origin.url.", git_result))

    remote_repo = normalize_repo_url(git_result.stdout)

    gh_result = run_command(
        [gh_bin, "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"],
        cwd=repo_root,
    )
    if gh_result.returncode != 0 or not gh_result.stdout.strip():
        fail(
            format_command_error(
                "Could not resolve the current GitHub repository via gh.",
                gh_result,
            )
        )

    gh_repo = gh_result.stdout.strip()

    if remote_repo != gh_repo:
        fail(
            "Git remote and gh repository do not match. "
            f"git={remote_repo}, gh={gh_repo}"
        )

    return gh_repo


def ensure_gh_auth(gh_bin: str, repo_root: Path) -> None:
    result = run_command([gh_bin, "auth", "status"], cwd=repo_root)
    if result.returncode != 0:
        fail(
            format_command_error(
                "gh is installed, but authentication is missing. Run 'gh auth login' first.",
                result,
            )
        )


def ensure_environment_exists(gh_bin: str, repo_root: Path, repo_name: str, env_name: str) -> None:
    result = run_command(
        [gh_bin, "api", f"repos/{repo_name}/environments/{env_name}"],
        cwd=repo_root,
    )
    if result.returncode != 0:
        fail(
            format_command_error(
                f"GitHub Environment '{env_name}' does not exist in {repo_name}. "
                "Create it in GitHub first, then rerun this script.",
                result,
            )
        )


def read_bootstrap_outputs(terraform_bin: str, bootstrap_dir: Path) -> dict[str, str]:
    result = run_command([terraform_bin, "output", "-json"], cwd=bootstrap_dir)
    if result.returncode != 0:
        fail(
            format_command_error(
                "Could not read Terraform outputs from bootstrap. "
                "Make sure bootstrap has been applied successfully first.",
                result,
            )
        )

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        fail(f"Terraform outputs were not valid JSON: {exc}")

    values: dict[str, str] = {}
    for env_var, output_name in REQUIRED_OUTPUTS.items():
        if output_name not in payload or "value" not in payload[output_name]:
            fail(f"Required bootstrap output is missing: {output_name}")

        value = payload[output_name]["value"]
        if value is None or str(value).strip() == "":
            fail(f"Bootstrap output is empty: {output_name}")

        values[env_var] = str(value)

    return values


def set_environment_variable(
    gh_bin: str,
    repo_root: Path,
    env_name: str,
    name: str,
    value: str,
) -> None:
    result = run_command(
        [gh_bin, "variable", "set", name, "--env", env_name, "--body", value],
        cwd=repo_root,
    )
    if result.returncode != 0:
        fail(
            format_command_error(
                f"Failed to set GitHub Environment variable {name}.",
                result,
            )
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sync bootstrap outputs into a GitHub Environment."
    )
    parser.add_argument(
        "environment",
        help="Environment name to sync, for example: dev",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the variables that would be written without updating GitHub.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    repo_root = get_repo_root()
    bootstrap_dir = repo_root / "bootstrap" / args.environment

    if not bootstrap_dir.is_dir():
        fail(f"Bootstrap directory does not exist: {bootstrap_dir}")

    git_bin = find_executable("git.exe", "git")
    terraform_bin = find_executable("terraform.exe", "terraform")
    gh_bin = find_executable("gh")

    ensure_repo_root(git_bin, repo_root)
    ensure_gh_auth(gh_bin, repo_root)
    repo_name = get_current_repo(git_bin, gh_bin, repo_root)
    ensure_environment_exists(gh_bin, repo_root, repo_name, args.environment)

    values = read_bootstrap_outputs(terraform_bin, bootstrap_dir)

    print("GitHub environment sync summary")
    print(f"Repository:  {repo_name}")
    print(f"Environment: {args.environment}")
    print("Variables:")
    for name, value in values.items():
        print(f"  - {name}={value}")

    if args.dry_run:
        print("Dry run enabled. No GitHub variables were changed.")
        return

    for name, value in values.items():
        set_environment_variable(gh_bin, repo_root, args.environment, name, value)

    print("GitHub Environment variables updated successfully.")


if __name__ == "__main__":
    main()
