# celld-stack

Single-claim install of [celld](https://celld.dev) — Deno's self-hosted Durable Objects runtime — onto a target Kubernetes cluster.

**Without CelldStack:** you assemble a StatefulSet, two Services, a PVC, bucket env, and credentials by hand, then keep advertise addresses and drain timeouts in sync with celld releases.

**With CelldStack:** apply one XR. The stack creates the namespace and installs the `celld` chart so each replica is a fleet node that coordinates through a bucket you own.

## The Journey

### Stage 1: Getting Started

```yaml
apiVersion: hops.ops.com.ai/v1alpha1
kind: CelldStack
metadata:
  name: celld
  namespace: default
spec:
  clusterName: my-cluster
```

This installs one celld node in namespace `celld`. For local, enable Azurite. For AWS, enable `spec.aws` so the stack creates a bucket and binds the celld ServiceAccount with EKS Pod Identity.

```yaml
spec:
  clusterName: my-cluster
  azurite:
    enabled: true
```

### Stage 2: Growing — AWS S3

```yaml
spec:
  clusterName: production-cluster
  aws:
    enabled: true
    region: us-east-2
    bucketName: hops-celld-production
```

The stack creates the bucket and an EKS Pod Identity for the celld ServiceAccount, scoped to that bucket. celld is pointed at `s3://hops-celld-production` and uses the default AWS credential chain (no static access keys). Requires an EKS cluster with the Pod Identity agent.

### Stage 3: Enterprise Scale

Use a dedicated S3-compatible store with a key prefix per environment (`s3://cells/prod`), inject credentials from External Secrets, and keep port 8081 on a private network. Gateway / DNS exposure is intentionally out of this stack — compose with your DNS and gateway stacks.

### Stage 4: Import Existing

Not applicable. This stack installs a Helm release; it does not adopt cloud resources by external name.

## Spec Reference

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `clusterName` | string | _required_ | Target cluster name; default for ProviderConfig names |
| `namespace` | string | `celld` | Namespace for the Helm release |
| `releaseName` | string | metadata.name | Helm release name |
| `chartVersion` | string | `0.3.0` | celld Helm chart version |
| `chartUrl` | string | — | Optional packaged-chart URL (skips the Helm repo) |
| `replicaCount` | integer | `1` | Fleet nodes |
| `bucket` | string | — | `s3://`, `gs://`, or `az://` bucket |
| `endpoint` | string | — | S3-compatible endpoint |
| `region` | string | `us-east-2` | Object-storage region |
| `credentials.existingSecret` | string | — | Secret with AWS_* keys (R2 / BYO). Unused when `aws.enabled` |
| `azurite.enabled` | boolean | `false` | Deploy in-cluster Azurite and point celld at `az://celld` (local/dev only) |
| `azurite.container` | string | `celld` | Blob container name |
| `aws.enabled` | boolean | `false` | Create S3 bucket + EKS Pod Identity and point celld at `s3://` |
| `aws.bucketName` | string | `hops-celld-<name>` | Globally unique S3 bucket name |
| `aws.region` | string | `us-east-2` | Bucket region |
| `aws.rolePrefix` | string | — | Prefix for the Pod Identity IAM role |
| `tags` | object | — | AWS tags merged with defaults |
| `persistence.size` | string | `10Gi` | CELLD_WATCH volume |
| `values` | object | — | Helm values merged with defaults |
| `overrideAllValues` | object | — | Helm values that replace all defaults |

## Status

| Field | Meaning |
|-------|---------|
| `ready` | Namespace, Helm release, Usage, and (when `aws.enabled`) bucket + Pod Identity are Ready |
| `release.name` / `release.namespace` | Installed Helm release |
| `service.name` / `service.port` | Public Worker Service (port 8080) |
| `bucket.name` / `bucket.id` | Observed S3 bucket when `aws.enabled` |
| `podIdentity.roleArn` / `podIdentity.associationId` | Observed Pod Identity when `aws.enabled` |

## Composed Resources

| Resource | Kind |
|---|---|
| `<name>-namespace` | `kubernetes.m.crossplane.io/Object` (Namespace) |
| `<releaseName>` | `helm.m.crossplane.io/Release` |
| `<name>-s3` | `s3.aws.m.upbound.io/Bucket` (when `aws.enabled`) |
| `<name>-celld` | `aws.hops.ops.com.ai/PodIdentity` (when `aws.enabled`) |
| `<name>-delete-helm-celld-before-namespace` | `protection.crossplane.io/Usage` (after both are Ready) |
| `<name>-delete-helm-celld-before-pod-identity` | `protection.crossplane.io/Usage` (after Helm + Pod Identity are Ready) |

## Development

```bash
make render             # Render all examples
make validate           # Validate against Crossplane schemas
make test               # KCL composition tests
make build              # Build the package
```

## License

Apache-2.0
