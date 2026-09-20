# Legacy Kubernetes examples

**Historical examples only. This directory is not the current Azure
deployment method.**

The current deployment uses [the Helm chart](../charts/homeoffice-commerce/)
with `values-azure.yaml`. See the [project README](../README.md).

## Why these files remain

These manifests document earlier experiments with raw Kubernetes YAML,
monitoring, and GitOps. They are retained for reference, not as an alternative
set of current deployment instructions.

## Do not apply this directory to the Azure cluster

- Application manifests can conflict with Helm-managed resources.
- Image references, storage settings, and configuration may be outdated.
- `database/secret.yaml` contains historical demonstration credentials.
  They are public examples, not the Azure database credentials. Do not reuse them.
- Monitoring manifests are examples, not evidence that monitoring is deployed
  or supported on the current AKS cluster.
- The Argo CD Application references the old `develop` workflow and includes
  automated synchronization/pruning behaviour. Do not apply it as-is.

CI/CD, Azure GitOps integration, and monitoring will be implemented and
documented in later milestones.