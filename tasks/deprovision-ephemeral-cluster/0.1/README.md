# deprovision-ephemeral-cluster task

The provision-ephemeral-cluster task deprovisions an ephemeral cluster within the Test Platform (OpenShift CI) infrastructure.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|testPlatformClusterClaimName|Name of the TestPlatformCluster Claim that was used to request an ephemeral cluster. This value comes from the results of the `provision-ephemeral-cluster` task||true|
|testPlatformClusterClaimNamespace|Namespace of the TestPlatformCluster Claim that was used to request an ephemeral cluster. This value comes from the results of the `provision-ephemeral-cluster` task||true|
|timeout|Wait for the ephemeral cluster to be ready until this timeout is reached|2h|false|
