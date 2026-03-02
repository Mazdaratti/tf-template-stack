# Route53 Private Zones Module

Reusable Terraform module to create and manage **Route53 private hosted zones** with optional baseline DNS records.

This module is designed to be reusable outside this repository and intentionally keeps scope narrow:

- creates one or more private hosted zones
- associates each zone with one or more VPCs
- optionally creates simple TTL-based records (`A`, `AAAA`, `CNAME`, `TXT`)
- applies consistent tagging across supported resources

---

## Use Cases

This module is useful when you need:

- internal DNS namespaces per environment (`dev.internal`, `corp.internal`, etc.)
- private DNS records for platform services or internal endpoints
- a standardized baseline for private zone creation across multiple projects
- predictable zone/record outputs for wiring into other modules

---

## Features (v1)

- Private hosted zone creation via a `zones` map
- Support for multiple VPC associations per zone
  - first association at zone creation time
  - additional associations via explicit Route53 zone association resources
- Optional baseline records per zone:
  - `A`
  - `AAAA`
  - `CNAME` (single value)
  - `TXT`
- Record key convention:
  - `"@"` creates apex record for the zone
  - any other key creates `<key>.<domain_name>`
- Standard tagging model:
  - enforced: `Project`, `Environment`, `ManagedBy`
  - merged with `common_tags`
  - optional per-zone tag extensions

---

## Module Responsibilities

This module is responsible for:

- creating Route53 private hosted zones
- associating zones with VPCs
- creating optional simple records
- returning zone IDs/names and created record FQDNs

This module is **not** responsible for:

- Route53 public hosted zones
- interface endpoint private DNS behavior
- advanced Route53 routing policies (weighted/latency/failover/geolocation)
- alias record management (baseline excludes alias blocks)

---

## Inputs Model

The main input is `zones`, a map keyed by a stable logical name.

Per zone, you provide:

- `domain_name`
- `vpc_associations` (at least one)
- optional zone settings (`comment`, `force_destroy`, `zone_tags`)
- optional `records` map for baseline DNS records

Record values are intentionally simple and explicit to keep the baseline clear and predictable.

---

## Usage

Minimal example:

```hcl
module "route53_private_zones" {
  source = "..."

  project_name = "my-project"
  environment  = "dev"

  zones = {
    internal = {
      domain_name = "dev.internal"

      vpc_associations = [
        { vpc_id = "vpc-1234567890abcdef0" }
      ]

      records = {
        api = {
          type   = "CNAME"
          ttl    = 300
          values = ["internal-api.example.local"]
        }
      }
    }
  }
}
```

For a runnable example, see:

- `examples/basic_usage`

---

## Notes

- `CNAME` records must contain exactly one value.
- Private hosted zones require at least one VPC association.
- Keep zone map keys stable to avoid unnecessary resource address changes.

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.34.0 |

## Resources

| Name | Type |
|------|------|
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone_association.extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name used for tagging (e.g., dev, staging, prod). | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for tagging. | `string` | n/a | yes |
| <a name="input_zones"></a> [zones](#input\_zones) | Map of private hosted zones to create.<br/><br/>Map key:<br/>  - Stable logical key used in Terraform state and outputs.<br/><br/>Value fields:<br/>  - domain\_name: DNS zone name (e.g., dev.internal)<br/>  - comment: optional hosted zone comment<br/>  - force\_destroy: whether to allow deleting non-empty zones<br/>  - vpc\_associations: list of VPCs to associate (at least one required)<br/>  - records: optional map of simple records (A, AAAA, CNAME, TXT)<br/>  - zone\_tags: optional per-zone tag additions/overrides | <pre>map(object({<br/>    domain_name = string<br/><br/>    comment       = optional(string)<br/>    force_destroy = optional(bool, false)<br/><br/>    vpc_associations = list(object({<br/>      vpc_id     = string<br/>      vpc_region = optional(string)<br/>    }))<br/><br/>    records = optional(map(object({<br/>      type   = string<br/>      ttl    = optional(number, 300)<br/>      values = list(string)<br/>    })), {})<br/><br/>    zone_tags = optional(map(string), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Additional tags to merge with enforced tags. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_record_fqdns"></a> [record\_fqdns](#output\_record\_fqdns) | Map of '<zone\_key>::<record\_key>' => computed record FQDN for created records. |
| <a name="output_zone_ids"></a> [zone\_ids](#output\_zone\_ids) | Map of logical zone key => Route53 private hosted zone ID. |
| <a name="output_zone_names"></a> [zone\_names](#output\_zone\_names) | Map of logical zone key => hosted zone DNS name. |
<!-- END_TF_DOCS -->
