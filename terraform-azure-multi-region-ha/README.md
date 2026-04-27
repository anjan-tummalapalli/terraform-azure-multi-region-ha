# Azure Multi-Region High Availability Infrastructure (Terraform)

This Terraform project deploys a **high-availability Azure setup across two regions**:
- **Primary region:** `Central India`
- **Failover region:** `East US 2`

It creates a complete active/passive topology:
1. Independent infrastructure in each region (resource group, VNet, subnet, NSG).
2. A regional Standard Load Balancer with a Linux VM Scale Set behind it.
3. Global DNS failover through Azure Traffic Manager using **Priority routing**.

Traffic Manager sends traffic to India by default and automatically fails over to US when the India endpoint is unhealthy.

## Architecture

```text
Clients
  |
  v
Azure Traffic Manager (Priority)
  |-- Priority 1 -> Central India Public LB -> VM Scale Set (>=2 instances)
  |-- Priority 2 -> East US 2 Public LB   -> VM Scale Set (>=2 instances)
```

## Files

- `versions.tf` - Terraform and provider versions.
- `variables.tf` - Input variables with defaults and validation.
- `main.tf` - Core infrastructure resources with inline comments.
- `outputs.tf` - Useful output values (global FQDN, regional endpoints).
- `terraform.tfvars.example` - Example variable file.
- `scripts/cloud-init.sh` - Bootstraps Nginx and prints region identity.

## Prerequisites

- Terraform `>= 1.5`
- Azure CLI
- Azure subscription with permissions to create networking/compute resources
- SSH public key for Linux VM access

## Quick Start

1. Authenticate to Azure:

```bash
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID_OR_NAME>"
```

2. Create your variable file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Update `terraform.tfvars` with your SSH public key and optional naming/tags.

4. Deploy:

```bash
terraform init
terraform plan
terraform apply
```

5. Get the global endpoint:

```bash
terraform output traffic_manager_fqdn
```

Open `http://<traffic_manager_fqdn>` in a browser. The page should show the active serving region.

## How Failover Works

- Traffic Manager probes each regional endpoint over HTTP `/` on port `80`.
- Endpoint priorities are fixed:
  - `1` = India (active)
  - `2` = US (standby)
- If the India endpoint fails health checks, Traffic Manager directs users to US automatically.

## Validation and Testing

- Check regional endpoint DNS names:

```bash
terraform output regional_public_fqdns
```

- Simulate regional failure (example):
  - Stop or scale down primary VMSS to unhealthy state.
  - Wait for Traffic Manager health probe cycle.
  - Refresh the global URL and verify US region appears in the page content.

## Clean Up

```bash
terraform destroy
```

## Notes

- This is an infrastructure baseline template; harden for production (private ingress, WAF, secrets management, backup, monitoring, policy).
- Running two VMSS + load balancers in two regions incurs ongoing Azure costs.
