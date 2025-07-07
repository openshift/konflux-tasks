# Run Prowjob Task
This task is designed to trigger a prowjob in the Konflux platform, allowing you to run integration tests with ephemeral clusters created in the Openshift CI environment, utilizing the features of ci-operator and prow.

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
1. **Create a pipeline** in your repository based on the [`/examples/pipeline.yaml`](/examples/pipeline.yaml) file.
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
| CLOUD_PROVIDER | Cloud provider to use for the test (one of aws, gcp, azure) | aws | false |
| OPENSHIFT_VERSION | OpenShift version to test against; must be in the format 4.x; if you are using a stable, fast or candidate channel, you can specify 4.x.y | 4.18 | false |
| CHANNEL_STREAM | OpenShift stream/channel to test against; one of stable, fast, candidate, 4-stable, nightly, konflux-nightly, ci; stable, fast and candidate are channels from the Cincinnati server, the other ones are streams from the release controller; always the latest version of the stream/channel will be used | stable | false |
| ARCHITECTURE | Architecture to test against; one of amd64, arm64 | amd64 | false |
| ARTIFACTS_BUILD_ROOT | Image to use for building the artifacts image, e.g. quay-proxy.ci.openshift.org/openshift/ci:ocp_builder_rhel-9-golang-1.22-openshift-4.17 |  | true |
| DOCKERFILE_ADDITIONS | Dockerfile additions to use for building the artifacts image, e.g. RUN make build |  | true |
| DEPLOY_TEST_COMMAND | Command that deploys and tests the OPERATOR_IMAGE on the cluster, e.g. make deploy && make test |  | true |
| BUNDLE_PRE_TEST_COMMAND | Only use with bundle image test! Pre-test command to run before the test, e.g. oc apply ... |  | false |
| BUNDLE_NS | Namespace to use if installing bundle image |  | false |
| PULL_SECRET | Secret created by the user in https://vault.ci.openshift.org/ in the test-credential namespace with the field .dockerconfigjson; necessary for private images |  | false |
| ENVS | Optional environment variables to inject into the test; separated by commas; e.g. VAR1=val1,VAR2=val2 |  | false |



## ⚙️ How It Works
The pipeline will trigger one of these prowjobs, depending on the specified parameters:
  - `periodic-ci-openshift-konflux-tasks-main-konflux-test-aws`
  - `periodic-ci-openshift-konflux-tasks-main-konflux-test-gcp`
  - `periodic-ci-openshift-konflux-tasks-main-konflux-test-azure`
  - `periodic-ci-openshift-konflux-tasks-main-konflux-test-bundle`

You can view recent runs here: 👉 [prowjob history](https://prow.ci.openshift.org/?job=periodic-ci-openshift-konflux-tasks-*)

The ci-operator configuration is located at: 📄 [ci-operator config YAML](https://github.com/openshift/release/blob/master/ci-operator/config/openshift/konflux-tasks/openshift-konflux-tasks-main.yaml)
> This configuration is dynamically patched with parameters defined in the pipeline before the job runs, allowing the job to execute according to your specific requirements.

Currently the following workflows are supported:
- [`ipi-aws`](https://steps.ci.openshift.org/workflow/ipi-aws)
- [`ipi-gcp`](https://steps.ci.openshift.org/workflow/ipi-gcp)
- [`ipi-azure`](https://steps.ci.openshift.org/workflow/ipi-azure)
- [`optional-operators-ci-operator-sdk-aws`](https://steps.ci.openshift.org/workflow/optional-operators-ci-operator-sdk-aws)


Explore all available workflows, their supported environment variables and  configuration details here: 🔗 [Step Registry](https://steps.ci.openshift.org)
