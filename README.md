# Konflux Tasks

This repository contains **Konflux tasks** for running parameterized prowjobs using Gangway.


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

## 📬 Contact
Need help or have a question?

📢 Reach out to the TestPlatform team at `#forum-ocp-testplatform` on the OpenShift Slack.

🐛 Open an issue in this repository.