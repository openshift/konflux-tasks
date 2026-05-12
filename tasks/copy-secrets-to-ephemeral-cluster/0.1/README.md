# copy-secrets-to-ephemeral-cluster task

The copy-secrets-to-ephemeral-cluster task copies Secrets from the current namespace into a configurable namespace on an ephemeral cluster. The name and content of each Secret is unaltered in the process.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|clusterCredentialsSecretRef|Name of the Secret containing kubeconfig and password to access the provisioned ephemeral cluster. This value comes from the results of the `provision-ephemeral-cluster` task||true|
|namespace|The destination namespace for the secrets. The namespace must already exist.||true|
|labelSelector|A label selector identifying the secrets to be copied||true|
