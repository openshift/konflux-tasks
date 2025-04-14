# Konflux Tasks

This repository contains Konflux tasks for running parameterized prowjobs using Gangway.


## Prerequisites

- Onboarded to the Konflux platform.
- Added gangway-token secret in your Konflux namespace and linked it to the Konflux service account. (https://konflux-ci.dev/docs/troubleshooting/registries/#check-if-the-secret-is-linked-to-the-service-account)


## Usage
1. Create a pipeline in your repository that would look like `/examples/pipeline.yaml.`
1. Create a integration-test in the Konflux platform referencing this pipeline.