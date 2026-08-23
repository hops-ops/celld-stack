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
                            version = "0.2.0"
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
]

items = _items
