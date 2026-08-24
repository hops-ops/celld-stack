### What's changed in v0.2.0

* feat: reuse hops AWS CLI creds for local S3 celld (by @patrickleet)

  Disable Pod Identity on kind and copy the hops local aws INI
  Secret into the celld namespace for real S3 access.

  Implements [[tasks/celld-stack]]


See full diff: [v0.1.0...v0.2.0](https://github.com/hops-ops/celld-stack/compare/v0.1.0...v0.2.0)
