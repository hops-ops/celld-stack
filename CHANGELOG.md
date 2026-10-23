### What's changed in v0.11.0

* feat: add RustFS object storage (#15) (by @patrickleet)

  * feat: add RustFS object storage for local celld fleets

  spec.rustfs.enabled installs the official RustFS chart (1.0.3,
  standalone) in the release namespace and points celld at
  s3://<bucket> on the in-cluster endpoint. It replaces Azurite for
  local use and takes precedence over azurite and aws.

  - Root keys come from a user Secret (RUSTFS_ACCESS_KEY,
    RUSTFS_SECRET_KEY); the stack copies it into the release namespace
    with AWS_* aliases, AWS_REGION and S3_ENDPOINT. No keys in manifests.
  - A one-shot Job creates the fleet bucket plus spec.rustfs.buckets and
    deploys the placeholder Worker only into an empty fleet bucket, so a
    celld pod restart never replaces the deployed application (the chart
    placeholder init container redeploys on every start).
  - celld renders after the bucket Job succeeds, then stays rendered.
  - Usages order teardown: celld, RustFS, credentials, namespace.
  - status.rustfs exposes endpoint, credentials Secret, buckets, ready.

  celld stays on chart 0.4.0 and image 0.6.2, the current releases.

  * test: set XR namespace on RustFS observed-resource fixtures

  Crossplane 2 render matches observed composed resources of a
  namespaced XR only in the XR's namespace. The KCL fixtures had no
  metadata.namespace, so the render ignored them and the test saw a
  first reconcile (status.rustfs.ready false, no RustFS release, no
  bucket Job). The YAML fixture already set the namespace; with the
  namespace removed, up composition render reproduces the CI failure.

  * fix: deploy the RustFS placeholder only on a 404

  The bucket Job marked the fleet bucket as empty on any head-object
  error, so an auth, network or 5xx failure could deploy the
  placeholder Worker over a real application. Now only a 404 does; any
  other error is printed and fails the Job, which retries.

  Checked against RustFS 1.0.3: missing key gives (404), wrong secret
  gives (403) and exits 1, an unreachable endpoint exits 1.

  Also documents why the Job is gated on the RustFS release existing
  rather than Ready.

  * fix: hash the full RustFS bucket Job spec into its name

  A Job's pod template is immutable, and the old name hashed only the
  buckets and celld image. A script, image or resource change on an
  existing install would then try to update the Job in place and leave
  the Object failing to sync.

  The Job spec is now one named template. It is rendered once, its
  sha256 goes into the Job name, and the same text is emitted. Any
  change makes a new Job; old Jobs are retired and the new one is
  idempotent.

  Fixtures and the render test now expect celld-rustfs-buckets-f68067af.


See full diff: [v0.10.0...v0.11.0](https://github.com/hops-ops/celld-stack/compare/v0.10.0...v0.11.0)
