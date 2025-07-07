# Konflux Tasks

This repository contains tasks for the Konflux platform, designed to facilitate integration testing with ephemeral clusters in the OpenShift CI environment. These tasks leverage the capabilities of ci-operator and prow to run tests efficiently.

## 📋 Overview
The repository includes tasks:
- **Run Prowjob**: This task triggers a prowjob based on the parameters you provide, allowing you to run integration tests.
- **Ephemeral Cluster Provisioning/Deprovisioning**: These tasks provision and deprovision ephemeral clusters in the OpenShift CI environment, without creating a prowjob, directly from the Konflux crossplane.
## 📬 Contact
Need help or have a question?

📢 Reach out to the TestPlatform team at `#forum-ocp-testplatform` on the OpenShift Slack.

🐛 Open an issue in this repository.