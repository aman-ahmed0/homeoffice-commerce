# HomeOffice Hub

A containerized e-commerce showcase deployed to Azure Kubernetes Service
using Terraform, Azure Container Registry, and Helm.

**Milestone 1: Azure deployment completed on September 20, 2026.**

The storefront and product catalogue were demonstrated through a public
Azure Load Balancer endpoint. The cluster runs on demand and is stopped
between development sessions to control costs.

This is a development portfolio deployment, not a production-ready service.

## Architecture

```text
Browser
   |
   | HTTP
   v
Azure Load Balancer
   |
   v
Next.js frontend
   |
   | /api/* forwarded internally
   v
Flask API / Gunicorn
   |
   v
PostgreSQL StatefulSet
   |
   v
32-GiB Azure Standard SSD persistent disk

Azure Container Registry --> AKS pulls application images
Terraform                --> Azure infrastructure and access assignments
Helm                     --> Application workloads and configuration
```

Azure manages the Kubernetes control plane. Two Ubuntu worker nodes run
the application and Kubernetes system workloads.

## Delivered

- Azure infrastructure defined with Terraform and a pinned AzureRM provider.
- AKS in Central India, using Kubernetes 1.36.3 and two Standard_D4as_v5 nodes.
- Application images stored in Azure Container Registry.
- Next.js production-mode startup and a non-root Gunicorn backend.
- Helm deployment with separate local and Azure values.
- PostgreSQL persistent storage using an explicit Standard SSD LRS class.
- Database credentials supplied through an existing Kubernetes Secret,
  outside Git and Helm values.
- Managed-identity access from AKS nodes to ACR.
- Microsoft Entra authentication and Azure RBAC for cluster administration.
- Kubernetes management endpoint restricted to an authorized public IP.
- Backend startup, liveness, and readiness probes.
- Subscription spending-limit protection and an AKS stop/start procedure.

## Demo

The application was demonstrated using its public IP on September 20, 2026.
A recording will be added after capture.

The demo is not continuously available: AKS is stopped between sessions.
A stopped cluster is intentional cost management, not an always-on hosting
commitment.

The current endpoint uses HTTP. Use synthetic demonstration data only.

## Repository guide

| Path | Purpose |
| --- | --- |
| `frontend/` | Next.js storefront |
| `backend/` | Flask product API and database integration |
| `charts/homeoffice-commerce/` | Current application deployment method |
| `infrastructure/` | Azure Terraform configuration |
| `docker-compose.yml` | Local development configuration |
| `kubernetes/` | Legacy examples, not the current Azure deployment |

Start with [Azure infrastructure](infrastructure/README.md).
Component notes: [frontend](frontend/README.md) and [backend](backend/README.md).

## Deployment configuration

The Helm chart uses:

- `values.yaml`: local Docker Desktop defaults.
- `values-azure.yaml`: ACR image addresses, image pulling, and Azure storage.

The Azure values currently reference this project's registry. Anyone
reproducing the deployment must substitute their own registry addresses.

Create the `ecommerce` namespace and `db-secret` separately before the first
application deployment. The Secret requires `POSTGRES_USER`,
`POSTGRES_PASSWORD`, and `POSTGRES_DB`.

Never apply the legacy example Secret to the Azure deployment.

## Cost management

AKS uses the Free cluster-management tier; worker VMs, storage, registry,
networking, and applicable traffic remain billable.

The operating target is below USD 100 per billing period, with roughly four
hours of cluster runtime daily. This is a target, not a guaranteed bill.

Stop AKS between sessions. Retained resources continue to incur charges.
Budget alerts are notifications, not automatic spending cutoffs.

## Current limitations

- Deployment and image publishing are currently manual.
- GitHub Actions and Argo CD are not yet operating this Azure deployment.
- HTTPS and application monitoring are not yet configured.
- Terraform state is currently local and must be protected outside Git.
- PostgreSQL has one replica on LRS storage; this is not a highly available
  database deployment.
- Database backup and restore procedures remain to be implemented.
- Dependency/base-image maintenance and frontend health probes remain open.
- One backend restart was observed during initial deployment; its cause
  has not yet been established.

## Roadmap

1. **CI/CD:** GitHub Actions, image build and scanning, ACR publishing,
   and passwordless Azure authentication.
2. **GitOps:** Argo CD tracking the intended branch and Azure Helm values.
3. **HTTPS:** TLS-enabled application access.
4. **Observability:** Prometheus/Grafana monitoring and actionable alerts.

Supporting work includes protected remote Terraform state, database
backup/restore, reproducible image references, and shutdown automation.

## Branch workflow

The target workflow is:

- `main`: the reviewed, demonstrated milestone.
- `feature/ci-cd`: the next development phase, created from `main`.

Future work is reviewed before it is merged into `main`.
Legacy branches are being retired as part of the milestone cleanup.

## Attribution and license

Application and infrastructure contributions are recorded in Git history.

All Rights Reserved.