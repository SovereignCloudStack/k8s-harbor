# Deployment manifests for Harbor

![Smoke test](https://github.com/SovereignCloudStack/k8s-harbor/workflows/CI/badge.svg)

## Repository content

This repository is intended to include all relevant configuration
and Kubernetes manifests for the deployment of Harbor inside SCS.

## Repository layout

This repository contains kustomize bases which may be referenced by
kustomize overlays which in turn define the deployment of whole
environments/clusters.

Also, usually flux2 resources are used for e.g. Helm, so flux2 controllers need to be installed in any destination cluster.

Repository structure:
- `base`
  - Contains Harbor base configuration and base helm release definition
  - Can be deployed as follows `kubectl apply -k base/`
    - In this case harbor is deployed via clusterIP and without additional services and persistence
    - Run `kubectl port-forward svc/harbor 8080:80` and access harbor at http://localhost:8080
  - Can be referenced by kustomize overlays, see e.g. `envs/public/`
    - To override base config use *harbor-config* configmap, see e.g. [harbor-config.yaml](envs/dev/harbor-config.yaml)
- `operators`
  - Contains helm release definitions for cert-manager, ingress-nginx, postgres-operator and redis-operator
  - All operators can be deployed at once using `kubectl apply -k operators/`
  - Separate operators can be deployed using e.g. `kubectl apply -k operators/redis/`
- `postgres`
  - Contains CR `postgresql` - postgresql cluster with basic configuration
  - Postgres-operator has to be installed first, and then postgresql cluster can be deployed by `kubectl apply -k postgres/`
- `redis`
  - Contains CR `RedisFailover` - redis sentinel with basic configuration
  - Redis-operator has to be installed first, and then redis sentinel cluster can be deployed by `kubectl apply -k redis/`
- `envs`
  - Contains kustomize overlays, e.g. `envs/public/`
  - Each subdirectory define deployment of Harbor
    - refers to `base`
    - adds *harbor-config* configmap
    - It can contain patches and other kustomizations, like `envs/public-ha/redis/`

## Documentation

Explore the documentation stored in the [docs](./docs) directory or view the rendered version online at https://docs.scs.community/docs/container/.

## Public environment threat model

We define the threat model to generally trust the network. It is mainly based on the fact, that all the services live
in the same k8s cluster, so services can communicate with each other without certificate verification because
we do not expect MITM attacks in the Kubernetes private network. In the case of HA databases (`envs/public-ha`), they are external to Harbor
, but they are still running in the same k8s cluster, so just basic auth is enabled here (it is easy to do).
We use TLS (with server certificate verification) only for external traffic (ingress, swift). Which seems sufficient
for now. There is tracking [issue](https://github.com/SovereignCloudStack/k8s-harbor/issues/27), where all the details can be found.

## Automated smoke tests

In order to ensure that every component inside of SCS behaves as
expected, there should be simple smoke tests.
These tests are implemented using GitHub Actions/Workflows.

## Further information

Harbor website: https://goharbor.io/
