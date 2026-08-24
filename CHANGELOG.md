### What's changed in v0.1.0

* feat: initial CelldStack XRD (by @patrickleet)

  Namespace + celld Helm release with Usage deletion ordering. Wraps
  hops-ops/celld-chart for self-hosted Durable Objects.

  Implements [[tasks/celld-stack]]

* feat: add spec.azurite.enabled for local emulator (by @patrickleet)

  When azurite.enabled, the Helm release deploys Azurite and points
  celld at az://celld. Production claims keep using a real bucket.

  Implements [[tasks/celld-stack]]

* chore: default celld chart to v0.2.1 for Azurite bootstrap (by @patrickleet)

  Implements [[tasks/celld-stack]]

* chore: default celld chart to v0.2.2 (by @patrickleet)

  Implements [[tasks/celld-stack]]

* fix: do not wait on Helm resources for CelldStack Ready (by @patrickleet)

  Azurite bootstrap can take longer than Helm wait. Ready follows a
  successful deploy instead.

  Implements [[tasks/celld-stack]]

* feat: provision S3 bucket and IAM key when aws.enabled (by @patrickleet)

  Composes Bucket, IAM user/policy/access key, and a namespaced Secret
  so celld can run against s3:// from the local control plane.

  Implements [[tasks/celld-stack]]

* feat: use EKS Pod Identity for CelldStack S3 access (by @patrickleet)

  Replace IAM user, access key, and secret copy with a composed
  PodIdentity bound to the celld ServiceAccount. Bucket-scoped
  inline policy. Depend on aws-pod-identity instead of provider-aws-iam.

  Implements [[tasks/celld-stack]]

* chore: default CelldStack chart to 0.3.1 from the helm repo (by @patrickleet)

  The celld chart is published at https://hops-ops.github.io/celld-chart.

  Implements [[tasks/celld-stack]]

* ci: use hops-ops/workflows-crossplane v3.2.0 (by @patrickleet)

  Replace unbounded-tech/workflows-crossplane v2.20.0 with the hops-ops
  fork at latest.

  Implements [[tasks/celld-stack]]


