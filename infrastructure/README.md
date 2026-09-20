# Azure infrastructure

Terraform configuration for the HomeOffice Hub Azure showcase.

This directory replaces the previous GCP infrastructure configuration.
No GCP provider is required for the current deployment.

## Resources

- Project resource group: `rg-homeoffice-dev`
- Azure Container Registry: Basic tier
- AKS: `aks-homeoffice-dev`, Central India, Kubernetes 1.36.3
- Two Ubuntu 24.04 worker nodes using Standard_D4as_v5
- Managed OS disks, 64 GiB per node
- Registry-scoped AcrPull assignment for the kubelet identity
- Cluster-scoped Kubernetes administration assignment for the designated user

AKS manages supporting resources in `rg-homeoffice-dev-nodes`.
Do not independently create that node resource group.

## Files

| File | Purpose |
| --- | --- |
| `providers.tf` | AzureRM provider version and subscription configuration |
| `variables.tf` | Shared inputs |
| `main.tf` | Resource group, registry, and registry output |
| `aks.tf` | AKS, access assignments, and cluster outputs |
| `.terraform.lock.hcl` | Committed provider selection and checksums |
| `terraform.tfvars` | Local input values, excluded from Git |

Required local inputs are `subscription_id`, `aks_admin_object_id`,
and `admin_ipv4_cidr`. The last value is the administrator's public IPv4
address with `/32`.

Use an account authorized to create resources and role assignments.
Azure service-provider registration is managed explicitly, not automatically.

## Preview changes

From the repository root:

```bash
terraform -chdir=infrastructure init
terraform -chdir=infrastructure fmt
terraform -chdir=infrastructure validate
terraform -chdir=infrastructure plan
```

Review costs and proposed changes before applying. Applying a saved plan
executes it without a further approval prompt.

## State and credentials

Terraform state is currently local. It is excluded from Git, but must not be
deleted or treated as disposable. Protected remote state is planned.

Do not commit state, saved plans, local variable files, kubeconfig files,
tokens, or database credentials.

The application's database Secret is created separately in Kubernetes.
Changing that Secret alone does not rotate an existing database password.

## Pause and resume

Stop compute between work sessions:

```bash
az aks stop --resource-group rg-homeoffice-dev --name aks-homeoffice-dev
az aks show --resource-group rg-homeoffice-dev --name aks-homeoffice-dev \
  --query powerState.code --output tsv
```

Confirm `Stopped`. Retained storage, registry, and networking can still cost money.

Resume:

```bash
az aks start --resource-group rg-homeoffice-dev --name aks-homeoffice-dev
```

Do not recreate the database Secret or reapply an old Terraform plan to resume.

If the administrator's public IP changes, update the API allowlist through
a reviewed Terraform change.

## Removal

A full teardown is destructive and different from stopping AKS.
Review `terraform -chdir=infrastructure plan -destroy` and preserve any
required database data before approving deletion.

Helm-managed disks and other supporting resources must be accounted for
during teardown; the Terraform resource count is not a complete disk inventory.