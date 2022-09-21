# Deployment manifests for Harbor

## Repository content

This repository is intended to include all relevant configuration
and Kubernetes manifests for the deployment of Harbor inside SCS.

## Repository layout

This repository contains kustomize bases which may be referenced by
kustomize overlays which in turn define the deployment of whole
environments/clusters.

Also, usually flux2 resources are used for e.g. Helm, so flux2 controllers need to be installed in any destination cluster.

## Automated smoke tests

In order to ensure that every component inside of SCS behaves as
expected, there should be simple smoke tests.
These tests are implemented using GitHub Actions/Workflows.

## References

| | |
| --- | --- |
| CI smoke test | ![Smoke test](https://github.com/SovereignCloudStack/k8s-harbor/workflows/CI/badge.svg) |



## Further information

Harbor website: https://goharbor.io/


