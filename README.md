# Konflux Tasks

This repository contains Konflux tasks for running parameterized prowjobs using Gangway.


## Prerequisites

- Onboarded to the Konflux platform.
- Added gangway-token secret in your Konflux tenant.


## Usage
1. Create a pipeline in your repository that would look like `/examples/pipeline.yaml.`
1. Create a integration-test in your Konflux tenant referencing this pipeline and set the context to be the component you want to test (remove the default application context).