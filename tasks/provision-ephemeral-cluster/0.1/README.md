# provision-ephemeral-cluster task

The provision-ephemeral-cluster task provisions an ephemeral cluster by leveraging the Test Platform infrastructure.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|buildRoot|This is going to be used as a `build_root` for the resulting ci-operator configuration. See https://docs.ci.openshift.org/docs/architecture/ci-operator/ for more information.||false|
|baseImages|This is going to be used as `base_images` for the resulting ci-operator configuration. See https://docs.ci.openshift.org/docs/architecture/ci-operator/ for more information.||false|
|externalImages|This is going to be used as `external_images` for the resulting ci-operator configuration. See https://docs.ci.openshift.org/docs/architecture/ci-operator/ for more information.||false|
|workflow|The workflow that will be used to provision the cluster. See https://steps.ci.openshift.org/#workflows for a complete list of any available workflow||false|
|env|Environmental variables available in the OpenShift CI infrastructure at provisioning time. This parameter is expected to be a valid JSON object|{}|false|
|clusterProfile|The cluster profile holds the IAM information for the account accountable for any resource created in a cloud provider. See https://docs.ci.openshift.org/docs/how-tos/adding-a-cluster-profile/ for more information||false|
|clusterClaim|The claim specifictions to provision an cluster from Hive. See https://docs.ci.openshift.org/docs/how-tos/cluster-claim/ for more information.||false|
|releases|The OpenShift release payload specification that will be installed on the ephemeral cluster. See https://docs.ci.openshift.org/docs/architecture/ci-operator/#describing-inclusion-in-an-openshift-release for more information. This parameter is expected to be a valid JSON object||true|
|resources|Set requests and limits on the containers involved in the ephemeral cluster provisioning procedure. See https://docs.ci.openshift.org/docs/architecture/ci-operator/ for more information. This parameter is expected to be a valid JSON object|{"*":{"requests":{"cpu":"200m"},"limits":{"memory":"400Mi"}}}|false|
|timeout|Wait for the ephemeral cluster to be ready until this timeout is reached|2h|false|

## Results
|name|description|
|---|---|
|secretRef|Name of a Secret containing a kubeconfig used to access the provisioned ephemeral cluster|
|testPlatformClusterClaimName|Name of the TestPlatformCluster Claim that is used to request an ephemeral cluster|
|testPlatformClusterClaimNamespace|Namespace of the TestPlatformCluster Claim that is used to request an ephemeral cluster|
