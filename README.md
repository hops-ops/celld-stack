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

This installs one celld node in namespace `celld`. For local, enable RustFS (S3-compatible, recommended) or Azurite. For AWS, enable `spec.aws` so the stack creates a bucket and binds the celld ServiceAccount with EKS Pod Identity.

```yaml
spec:
  clusterName: my-cluster
  azurite:
    enabled: true
```

### Stage 1b: Local S3 with RustFS

```yaml
spec:
  clusterName: my-cluster
  rustfs:
    enabled: true
    buckets:
      - game-services          # extra application buckets; the fleet bucket is always created
    credentialsSecretRef:
      name: celld-rustfs-credentials
```

Create the root credentials yourself; the stack never generates or embeds keys:

```bash
kubectl -n default create secret generic celld-rustfs-credentials \
  --from-literal=RUSTFS_ACCESS_KEY="$(openssl rand -hex 12)" \
  --from-literal=RUSTFS_SECRET_KEY="$(openssl rand -hex 24)"
```

The stack copies that Secret into the release namespace as `<releaseName>-rustfs`
with `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` and
`S3_ENDPOINT` added, installs the official RustFS chart (standalone, one PVC),
creates `celld` plus the extra buckets with a one-shot Job (which also deploys
a fetch-only placeholder Worker once, only into an empty fleet bucket, so pod
restarts never replace your application), and then installs
celld against `s3://celld` on `http://<releaseName>-rustfs-svc.<namespace>.svc.cluster.local:9000`.
Applications in the cluster can mount the same `<releaseName>-rustfs` Secret
(`envFrom`) to reach their buckets with any S3 client. RustFS takes precedence
over `azurite` and `aws`.

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

On a local kind cluster, disable Pod Identity and reuse hops `local aws` credentials (the `aws-creds` Secret):

```yaml
spec:
  clusterName: default
  aws:
    enabled: true
    region: us-east-2
    bucketName: hops-celld-s3-034489662075
    podIdentity:
      enabled: false
```


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
| `chartVersion` | string | `0.4.0` | celld Helm chart version |
| `chartUrl` | string | — | Optional packaged-chart URL (skips the Helm repo) |
| `replicaCount` | integer | `1` | Fleet nodes |
| `bucket` | string | — | `s3://`, `gs://`, or `az://` bucket |
| `endpoint` | string | — | S3-compatible endpoint |
| `region` | string | `us-east-2` | Object-storage region |
| `credentials.existingSecret` | string | — | Secret with AWS_* keys (R2 / BYO). Unused when `aws.enabled` |
| `azurite.enabled` | boolean | `false` | Deploy in-cluster Azurite and point celld at `az://celld` (local/dev only) |
| `azurite.container` | string | `celld` | Blob container name |
| `rustfs.enabled` | boolean | `false` | Deploy in-cluster RustFS and point celld at it (wins over `azurite`/`aws`) |
| `rustfs.bucket` | string | `celld` | Fleet bucket name |
| `rustfs.buckets` | string[] | — | Extra buckets to create |
| `rustfs.credentialsSecretRef` | object | `<name>-rustfs-credentials` in the XR namespace | Secret with `RUSTFS_ACCESS_KEY` / `RUSTFS_SECRET_KEY` |
| `rustfs.persistence.size` | string | `2Gi` | RustFS data volume |
| `rustfs.persistence.storageClassName` | string | cluster default | RustFS storage class |
| `rustfs.values` | object | — | RustFS chart values merged with stack defaults |
| `aws.enabled` | boolean | `false` | Create S3 bucket and point celld at `s3://` |
| `aws.bucketName` | string | `hops-celld-<name>` | Globally unique S3 bucket name |
| `aws.region` | string | `us-east-2` | Bucket region |
| `aws.podIdentity.enabled` | boolean | `true` | Compose EKS Pod Identity (disable on kind/local) |
| `aws.credentialsSecretRef` | object | `aws-creds` when Pod Identity is off | Hops `local aws` INI Secret to copy into the celld namespace |
| `aws.rolePrefix` | string | — | Prefix for the Pod Identity IAM role |
| `tags` | object | — | AWS tags merged with defaults |
| `persistence.size` | string | `10Gi` | CELLD_WATCH volume |
| `values` | object | — | Helm values merged with defaults |
| `overrideAllValues` | object | — | Helm values that replace all defaults |

## Status

| Field | Meaning |
|-------|---------|
| `ready` | Namespace, Helm release, Usage, and (when `aws.enabled`) bucket + Pod Identity, or (when `rustfs.enabled`) RustFS + buckets are Ready |
| `release.name` / `release.namespace` | Installed Helm release |
| `service.name` / `service.port` | Public Worker Service (port 8080) |
| `bucket.name` / `bucket.id` | Observed S3 bucket when `aws.enabled` |
| `podIdentity.roleArn` / `podIdentity.associationId` | Observed Pod Identity when `aws.enabled` |
| `rustfs.endpoint` / `rustfs.credentialsSecret` | In-cluster S3 endpoint and the Secret S3 clients mount (when `rustfs.enabled`) |
| `rustfs.buckets` / `rustfs.ready` | Buckets the bucket Job ensured; credentials, RustFS and buckets ready |

## Composed Resources

| Resource | Kind |
|---|---|
| `<name>-namespace` | `kubernetes.m.crossplane.io/Object` (Namespace) |
| `<releaseName>` | `helm.m.crossplane.io/Release` |
| `<name>-s3` | `s3.aws.m.upbound.io/Bucket` (when `aws.enabled`) |
| `<name>-celld` | `aws.hops.ops.com.ai/PodIdentity` (when `aws.enabled`) |
| `<name>-delete-helm-celld-before-namespace` | `protection.crossplane.io/Usage` (after both are Ready) |
| `<name>-rustfs-creds` | `kubernetes.m.crossplane.io/Object` (Secret, when `rustfs.enabled`) |
| `<releaseName>-rustfs` | `helm.m.crossplane.io/Release` (RustFS, when `rustfs.enabled`) |
| `<name>-rustfs-buckets-<hash>` | `kubernetes.m.crossplane.io/Object` (bucket Job, when `rustfs.enabled`) |
| `<name>-delete-helm-celld-before-rustfs`, `-before-rustfs-creds`, `<name>-delete-helm-rustfs-before-namespace`, `-before-rustfs-creds` | `protection.crossplane.io/Usage` (RustFS teardown order) |
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
