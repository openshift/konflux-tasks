# Provide Prowjob Task
This Tekton task triggers a already existing Prowjob with the images build in the Konflux platform, allowing you to run integration or custom tests using ephemeral OpenShift CI clusters. It dynamically patches the ci-operator configuration with your parameters and launches the job via Gangway.

## ✅ Prerequisites
To use these tasks, ensure you’ve completed the following:
- You are **onboarded to the Konflux platform**.
- You have added a **gangway token secret** to your Konflux tenant. The secret must contain a key named `token`.
- It might be needed to define custom timeouts on the pipeline level for individual IntegrationTestScenarios, based on your test. The default is 2h. Check the [konflux documentation](https://konflux-ci.dev/docs/testing/integration/editing/) for more details.

To get the token used to trigger prowjobs, run:
```
oc --context app.ci -n konflux-tp extract secret/gangway-token-dockercfg-wbq9f
```
> 🔑 This is a long-lived token used only for triggering prowjobs via this pipeline.

## 🛠️ Usage
1. **Create a pipeline** in your repository based on the [`/examples/pipeline.yaml`](/examples/provide-prowjob/pipeline.yaml) file.
2. **Define an integration-test** in your Konflux tenant:
    - Reference the pipeline you created.
    - Set the context to the specific component you want to test (remove the default application context).

## Pipeline Flow
The pipeline consists of the following tasks:
- **run-prowjob**: This task triggers a prowjob based on the parameters you provide.
- **report-prowjob-status**: This task waits for the prowjob to complete, checks its status and reports the result.

## Parameters
| name | description | default value | required |
|------|-------------|----------------|----------|
| SNAPSHOT | Snapshot of the application |  | true |
| GANGWAY_TOKEN | Token to authenticate with gangway | gangway-token | false |
| PROWJOB_NAME | Name of the prowjob to trigger |  | true |
| VARIANT | Variant to use in the ci-operator config, e.g. ocp418 |  | false |
| IMAGE_IN_CONFIG | Image name as referenced in the ci-operator config that should be replaced with the built image |  | true |
| ARTIFACTS_BUILD_ROOT | Image to use for building the artifacts image, e.g. quay-proxy.ci.openshift.org/openshift/ci:ocp_builder_rhel-9-golang-1.22-openshift-4.17 |  | true |
| DOCKERFILE_ADDITIONS | Dockerfile additions to use for building the artifacts image, e.g. RUN make build |  | true |
| INCLUDE_IMAGES | Bool flag whether to include the `images` stanza in the ci-operator config | 0 | false |
| INCLUDE_OPERATOR | Bool flag whether to include the `operator` stanza in the ci-operator config | 0 | false |

## ⚙️ How It Works
Patch ci-operator Config:
Downloads and patches the ci-operator config for your repo and branch, replacing the referenced as `IMAGE_IN_CONFIG` and optionally removing images/operator stanzas.

Trigger Prowjob:
Triggers the specified prowjob with the patched ci-operator config and parameters you provided.