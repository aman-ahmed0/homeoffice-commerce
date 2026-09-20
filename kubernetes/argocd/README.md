# Legacy Argo CD example

**Not deployed as part of the current Azure milestone. Do not apply as-is.**

The adjacent `application.yaml` belongs to an earlier workflow that watches
the `develop` branch and the legacy `kubernetes/` directory.

Its automated synchronization and pruning settings are not approved for
the current Helm-managed Azure deployment.

The future GitOps milestone will define:

- The intended repository branch and chart path.
- Azure-specific Helm values and image updates.
- Secret handling outside Git.
- A deliberate transition of application ownership to Argo CD.
- Reviewed synchronization, pruning, and rollback behaviour.

See the [current roadmap](../../README.md#roadmap).