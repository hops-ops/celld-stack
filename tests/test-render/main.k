import models.ai.com.ops.hops.v1alpha1 as stacksv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

# ==============================================================================
# Unit tests for CelldStack XRD
#
# Philosophy: test YOUR API, not the provider's.
# ==============================================================================

_items = [
    # ==========================================================================
    # Test 1: minimal claim renders namespace + celld Helm release.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "minimal-renders-namespace-and-helm"
        spec = {
            compositionPath = "apis/celldstacks/composition.yaml"
            xrdPath = "apis/celldstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.CelldStack {
                metadata.name = "test-celld"
                spec.clusterName = "my-cluster"
            }
            assertResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "test-celld-namespace"
                    spec.forProvider.manifest = {
                        apiVersion = "v1"
                        kind = "Namespace"
                        metadata.name = "celld"
                    }
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-celld"
                    spec.forProvider = {
                        chart = {
                            name = "celld"
                            repository = "https://hops-ops.github.io/celld-chart"
                            # renovate: datasource=github-releases depName=hops-ops/celld-chart
                            version = "0.5.1"
                        }
                        namespace = "celld"
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 2: custom labels merge with the stack's defaults.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "custom-labels-merged-with-defaults"
        spec = {
            compositionPath = "apis/celldstacks/composition.yaml"
            xrdPath = "apis/celldstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.CelldStack {
                metadata.name = "labeled-celld"
                spec = {
                    clusterName = "my-cluster"
                    labels = {team = "platform", environment = "staging"}
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata = {
                        name = "labeled-celld"
                        labels = {
                            "hops.ops.com.ai/managed" = "true"
                            "hops.ops.com.ai/celldstack" = "labeled-celld"
                            team = "platform"
                            environment = "staging"
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 3: custom chartVersion propagates to the Helm release.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "custom-chart-version-propagates"
        spec = {
            compositionPath = "apis/celldstacks/composition.yaml"
            xrdPath = "apis/celldstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.CelldStack {
                metadata.name = "version-test"
                spec = {
                    clusterName = "my-cluster"
                    chartVersion = "0.3.0"
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "version-test"
                    spec.forProvider.chart.version = "0.3.0"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 4: custom namespace propagates to namespace Object and Helm release.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "custom-namespace-propagates"
        spec = {
            compositionPath = "apis/celldstacks/composition.yaml"
            xrdPath = "apis/celldstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.CelldStack {
                metadata.name = "ns-test"
                spec = {
                    clusterName = "my-cluster"
                    namespace = "celld-system"
                }
            }
            assertResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "ns-test-namespace"
                    spec.forProvider.manifest.metadata.name = "celld-system"
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "ns-test"
                    spec.forProvider.namespace = "celld-system"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 5: bucket and credentials pass through as Helm values.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "bucket-and-credentials-pass-through"
        spec = {
            compositionPath = "apis/celldstacks/composition.yaml"
            xrdPath = "apis/celldstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.CelldStack {
                metadata.name = "bucket-test"
                spec = {
                    clusterName = "my-cluster"
                    bucket = "s3://my-cells-bucket"
                    region = "us-west-2"
                    endpoint = "https://account.r2.cloudflarestorage.com"
                    credentials = {existingSecret = "celld-aws"}
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "bucket-test"
                    spec.forProvider.values = {
                        celld = {
                            bucket = "s3://my-cells-bucket"
                            region = "us-west-2"
                            endpoint = "https://account.r2.cloudflarestorage.com"
                        }
                        credentials = {existingSecret = "celld-aws"}
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 6: helmProviderConfigRef defaults to clusterName.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "helm-provider-config-defaults-to-cluster-name"
        spec = {
            compositionPath = "apis/celldstacks/composition.yaml"
            xrdPath = "apis/celldstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.CelldStack {
                metadata.name = "provider-test"
                spec.clusterName = "prod-cluster"
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "provider-test"
                    spec.providerConfigRef = {
                        name = "prod-cluster"
                        kind = "ProviderConfig"
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 7: overrideAllValues replaces chart values entirely.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "override-all-values-replaces-defaults"
        spec = {
            compositionPath = "apis/celldstacks/composition.yaml"
            xrdPath = "apis/celldstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.CelldStack {
                metadata.name = "override-test"
                spec = {
                    clusterName = "my-cluster"
                    overrideAllValues = {
                        replicaCount = 3
                        celld = {bucket = "s3://override"}
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "override-test"
                    spec.forProvider.values = {
                        replicaCount = 3
                        celld = {bucket = "s3://override"}
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 8: chartUrl uses a direct chart archive instead of the repo.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "chart-url-uses-direct-archive"
        spec = {
            compositionPath = "apis/celldstacks/composition.yaml"
            xrdPath = "apis/celldstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.CelldStack {
                metadata.name = "url-test"
                spec = {
                    clusterName = "my-cluster"
                    chartUrl = "https://example.invalid/celld-0.1.0.tgz"
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "url-test"
                    spec.forProvider.chart.url = "https://example.invalid/celld-0.1.0.tgz"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 9: azurite.enabled deploys Azurite and points celld at az://celld.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "azurite-enabled-configures-emulator"
        spec = {
            compositionPath = "apis/celldstacks/composition.yaml"
            xrdPath = "apis/celldstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.CelldStack {
                metadata.name = "azurite-test"
                spec = {
                    clusterName = "my-cluster"
                    azurite = {enabled = True}
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "azurite-test"
                    spec.forProvider.values = {
                        celld = {bucket = "az://celld"}
                        azurite = {enabled = True, container = "celld"}
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 10: aws.enabled renders an S3 bucket and PodIdentity, not IAM users.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "aws-enabled-renders-s3-bucket-and-pod-identity"
        spec = {
            compositionPath = "apis/celldstacks/composition.yaml"
            xrdPath = "apis/celldstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.CelldStack {
                metadata.name = "aws-test"
                spec = {
                    clusterName = "my-cluster"
                    aws = {
                        enabled = True
                        bucketName = "hops-celld-aws-test"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "s3.aws.m.upbound.io/v1beta1"
                    kind = "Bucket"
                    metadata.name = "aws-test-s3"
                    spec.forProvider.region = "us-east-2"
                }
                {
                    apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                    kind = "PodIdentity"
                    metadata.name = "aws-test-celld"
                    spec = {
                        clusterName = "my-cluster"
                        region = "us-east-2"
                        serviceAccount = {
                            name = "aws-test-celld"
                            namespace = "celld"
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 11: local S3 copies hops aws-creds and skips PodIdentity.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "aws-local-creds-skip-pod-identity"
        spec = {
            compositionPath = "apis/celldstacks/composition.yaml"
            xrdPath = "apis/celldstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.CelldStack {
                metadata.name = "local-s3"
                spec = {
                    clusterName = "default"
                    aws = {
                        enabled = True
                        bucketName = "hops-celld-local-s3"
                        podIdentity = {enabled = False}
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "s3.aws.m.upbound.io/v1beta1"
                    kind = "Bucket"
                    metadata.name = "local-s3-s3"
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "local-s3-aws-creds"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 12: rustfs.enabled first copies credentials and waits to install.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "rustfs-copies-credentials-before-installing"
        spec = {
            compositionPath = "apis/celldstacks/composition.yaml"
            xrdPath = "apis/celldstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.CelldStack {
                metadata.name = "celld"
                metadata.namespace = "game"
                spec = {
                    clusterName = "my-cluster"
                    rustfs = {enabled = True}
                }
            }
            assertResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "celld-rustfs-creds"
                    spec.forProvider.manifest = {
                        apiVersion = "v1"
                        kind = "Secret"
                        metadata = {name = "celld-rustfs", namespace = "celld"}
                        data = {
                            S3_ENDPOINT = "aHR0cDovL2NlbGxkLXJ1c3Rmcy1zdmMuY2VsbGQuc3ZjLmNsdXN0ZXIubG9jYWw6OTAwMA=="
                            AWS_REGION = "dXMtZWFzdC0x"
                        }
                    }
                }
                {
                    apiVersion = "hops.ops.com.ai/v1alpha1"
                    kind = "CelldStack"
                    status.rustfs = {
                        endpoint = "http://celld-rustfs-svc.celld.svc.cluster.local:9000"
                        ready = False
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 13: with RustFS up and buckets created, celld targets RustFS.
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "rustfs-ready-points-celld-at-rustfs"
        spec = {
            compositionPath = "apis/celldstacks/composition.yaml"
            xrdPath = "apis/celldstacks/definition.yaml"
            # Namespaced XR: observed MRs must carry the XR namespace to match.
            observedResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata = {
                        name = "celld-namespace"
                        namespace = "default"
                        annotations = {"crossplane.io/composition-resource-name" = "namespace"}
                    }
                    status.conditions = [{type = "Ready", status = "True"}]
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata = {
                        name = "celld-rustfs-creds"
                        namespace = "default"
                        uid = "0b6d3f0e-0000-4000-8000-000000000001"
                        annotations = {"crossplane.io/composition-resource-name" = "rustfs-creds-secret"}
                    }
                    status.conditions = [{type = "Ready", status = "True"}]
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata = {
                        name = "celld-rustfs"
                        namespace = "default"
                        annotations = {"crossplane.io/composition-resource-name" = "helm-release-rustfs"}
                    }
                    status = {
                        atProvider.revision = 1
                        conditions = [{type = "Ready", status = "True"}]
                    }
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata = {
                        name = "celld-rustfs-buckets-f68067af"
                        namespace = "default"
                        annotations = {"crossplane.io/composition-resource-name" = "rustfs-buckets-job"}
                    }
                    status = {
                        atProvider.manifest.status.succeeded = 1
                        conditions = [{type = "Ready", status = "True"}]
                    }
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata = {
                        name = "celld"
                        namespace = "default"
                        annotations = {"crossplane.io/composition-resource-name" = "helm-release-celld"}
                    }
                    status = {
                        atProvider.revision = 1
                        conditions = [{type = "Ready", status = "True"}]
                    }
                }
            ]
            timeoutSeconds = 60
            validate = False
            xr = stacksv1alpha1.CelldStack {
                metadata.name = "celld"
                metadata.namespace = "default"
                spec = {
                    clusterName = "my-cluster"
                    rustfs = {
                        enabled = True
                        buckets = ["game-services"]
                        credentialsSecretRef.name = "celld-rustfs-credentials"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "celld-rustfs"
                    spec.forProvider = {
                        chart = {
                            name = "rustfs"
                            repository = "https://charts.rustfs.com"
                            version = "1.0.4"
                        }
                        namespace = "celld"
                        values = {
                            fullnameOverride = "celld-rustfs"
                            mode.standalone.enabled = True
                            secret.existingSecret = "celld-rustfs"
                            ingress.enabled = False
                        }
                    }
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "celld-rustfs-buckets-f68067af"
                }
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "celld"
                    spec.forProvider.values = {
                        bootstrapPlaceholder = False
                        celld = {
                            bucket = "s3://celld"
                            endpoint = "http://celld-rustfs-svc.celld.svc.cluster.local:9000"
                            region = "us-east-1"
                        }
                        credentials = {existingSecret = "celld-rustfs"}
                        azurite = {enabled = False}
                    }
                }
                {
                    apiVersion = "protection.crossplane.io/v1beta1"
                    kind = "Usage"
                    metadata.name = "celld-delete-helm-celld-before-rustfs"
                }
                {
                    apiVersion = "hops.ops.com.ai/v1alpha1"
                    kind = "CelldStack"
                    status.rustfs = {
                        credentialsSecret = "celld-rustfs"
                        buckets = ["celld", "game-services"]
                        ready = True
                    }
                }
            ]
        }
    }
]

items = _items
