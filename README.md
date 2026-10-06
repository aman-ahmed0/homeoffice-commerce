# HomeOffice Commerce

A three-tier e-commerce app (Next.js, Flask, PostgreSQL) running on Azure
Kubernetes Service, built with Terraform and delivered through GitHub Actions
and Argo CD.

![Architecture: GitHub Actions builds, tests and scans images, pushes them to
Azure Container Registry, and Argo CD syncs the Helm chart to AKS](docs/architecture.gif)

This is a portfolio project, not a production service. The cluster is stopped
between work sessions to control cost, so the public demo is not always online.

## What this project demonstrates

- **Infrastructure as code:** Terraform builds the resource group, container
  registry, AKS cluster, CI identity and role assignments.
- **CI on every pull request:** secret scanning, Terraform and Helm checks,
  image build, a start-up smoke test, and a vulnerability scan.
- **Passwordless cloud access from CI:** GitHub Actions signs in to Azure with
  OIDC (workload identity federation). No cloud password is stored in GitHub.
- **GitOps delivery:** Argo CD deploys exactly what the Helm chart on `main`
  describes. Every change to production goes through a reviewed pull request.
- **Protected main branch:** a GitHub ruleset requires a pull request and four
  green checks, and blocks force pushes and deletion.
- **Hardened images:** non-root containers, a distroless frontend runtime,
  pinned base images and pinned backend dependencies.
- **Kubernetes workloads:** a backend Deployment with startup, liveness and
  readiness probes and resource limits, a PostgreSQL StatefulSet on a 32 GiB Azure Standard SSD disk, and internal
  ClusterIP and headless Services.

## How a change reaches production

1. **Pull request.** A developer pushes a branch and opens a pull request to `main`.
2. **CI checks.** GitHub Actions runs four required checks:
   - Source safeguards: no state or credential files, Trivy secret scan.
   - Terraform and Helm: `terraform fmt` and `validate`, `helm lint` and `template`.
   - Build and scan (backend) and Build and scan (frontend): build the image,
     start it and call its endpoints, then scan it with Trivy. Any High or
     Critical finding fails the check.
3. **Merge.** The ruleset allows the merge only when all four checks are green
   and the branch is up to date with `main`.
4. **Publish.** On `main`, CI signs in to Azure with OIDC and pushes both
   images to Azure Container Registry, tagged with the commit SHA.
5. **Deploy pull request.** A second small pull request sets that SHA as the
   image tag in `charts/homeoffice-commerce/values-azure.yaml`.
6. **Sync.** Argo CD detects that the rendered chart differs from the cluster,
   shows the diff, and applies it when synced. Kubernetes rolls out the new
   Pods; the old Pods keep serving until the new ones pass their probes.

Synchronisation is manual by design, so every deployment is reviewed in the
Argo CD diff before it is applied.

## Lessons from real incidents

**A dependency upgrade crashed the backend; a smoke test now catches it.**
The first GitOps deployment rolled out a backend image that crashed on start
with `No module named 'psycopg'`. Cause: the backend's requirements were not
pinned, and SQLAlchemy 2.1 (released 2026-09-24) changed the default
PostgreSQL driver from psycopg2 to psycopg 3. The rolling update kept the old
backend Pod serving while the new one crashed. Fixes:

- The connection URL names the driver explicitly (`postgresql+psycopg2://`).
- All backend dependencies are pinned to the versions verified in Azure.
- CI now starts every image before scanning it (`scripts/smoke-test.sh`). The
  backend test runs against a throwaway PostgreSQL 15 container and requires
  `/healthz` and a non-empty `/api/products`. The original broken image fails
  this test.

**OIDC sign-in failed on the subject claim.** Azure rejected the first CI
sign-in (`AADSTS700213`) because the federated credential used the classic
subject format, while this repository's tokens use GitHub's immutable subject
format (owner and repository IDs included). The Terraform-managed credential
was corrected and the sign-in passed.

## Repository layout

| Path | Purpose |
| --- | --- |
| `frontend/` | Next.js storefront |
| `backend/` | Flask product API (Gunicorn) |
| `charts/homeoffice-commerce/` | Helm chart: the deployment source for Argo CD |
| `argocd/homeoffice-app.yaml` | Argo CD Application for the Azure deployment |
| `infrastructure/` | Terraform for Azure |
| `.github/workflows/ci.yml` | CI pipeline |
| `scripts/smoke-test.sh` | Start-up test used by CI and locally |
| `docs/` | Architecture diagram |
| `docker-compose.yml` | Local development |
| `kubernetes/` | Legacy examples. Not used by the Azure deployment. |

## Run it locally

Requires Docker with Compose.

```bash
docker compose up --build
```

Open http://localhost:3000. Compose uses demo database credentials that are
intended for local use only.

## Deploy to Azure

Summary only; see [infrastructure/README.md](infrastructure/README.md) for
details. Substitute your own subscription, registry name and IP address.

1. **Infrastructure.** In `infrastructure/`, create a local `terraform.tfvars`
   (never committed) with `subscription_id`, `location` and `admin_ipv4_cidr`,
   then run `terraform init`, `terraform plan -out=<file>` and
   `terraform apply <file>`.
2. **Database Secret.** The chart reads the database credentials from an
   existing Secret, which is deliberately kept out of Git:

   ```bash
   kubectl create namespace ecommerce
   kubectl -n ecommerce create secret generic db-secret \
     --from-literal=POSTGRES_USER=<user> \
     --from-literal=POSTGRES_PASSWORD=<strong-password> \
     --from-literal=POSTGRES_DB=<database>
   ```

   Create it once, before the first deployment. Changing it later does not
   change the password of an existing database.
3. **Argo CD.** Install Argo CD with its official Helm chart, then apply the
   Application:

   ```bash
   helm repo add argo https://argoproj.github.io/argo-helm
   helm install argocd argo/argo-cd --version 10.9.6 \
     --namespace argocd --create-namespace --wait
   kubectl apply -f argocd/homeoffice-app.yaml
   ```

   Open the UI with `kubectl port-forward service/argocd-server -n argocd 8080:443`,
   review the diff, and sync.
4. **CI publishing.** Add the repository secrets `AZURE_CLIENT_ID`,
   `AZURE_TENANT_ID` and `AZURE_SUBSCRIPTION_ID` from the Terraform outputs and
   your subscription.

## Security choices

- No long-lived cloud credentials in CI: OIDC tokens, limited to the `main`
  branch, with the `AcrPush` role on the registry only.
- AKS uses Microsoft Entra ID with Azure RBAC; local accounts are disabled.
- The AKS API server accepts connections only from the administrator's IP.
- The Argo CD UI is not exposed publicly; it is reached through port-forward.
- Containers run as non-root users.
- Trivy fails CI on High or Critical vulnerabilities, including those without
  a published fix. A passing scan is a point-in-time result, not a certification.
- Database credentials live only in a Kubernetes Secret, never in Git.

## Cost management

AKS uses the Free control-plane tier, with two `Standard_D4as_v5` nodes in
Central India. Nodes, disks, registry and networking are billable. The
cluster is stopped between sessions (`az aks stop`); a stopped cluster keeps
its Kubernetes objects and disks, which continue to cost a small amount.

## Known limitations and next steps

- HTTP only; HTTPS is planned (Gateway API with an HTTPRoute and TLS).
- The image tag in the deploy pull request is updated by hand. Options under
  review: CI opens the pull request, or Argo CD Image Updater.
- `db-secret` is created by hand. Next step: External Secrets Operator with
  Azure Key Vault, so Git describes the Secret without containing it.
- Terraform state is local. Next step: remote state in Azure Storage.
- PostgreSQL runs as a single replica on locally redundant storage, without
  automated backups.
- Not yet in place: frontend health probes, NetworkPolicies, monitoring and
  alerting.

## License

All Rights Reserved.
