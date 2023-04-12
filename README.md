# Deployment manifests for Harbor

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
    - To override base config use *harbor-config* configmap, see e.g. [harbor-config.yaml](envs/ci-testing/harbor-config.yaml)
- `operators`
  - Contains helm release definitions for cert-manager, ingress-nginx, postgres-operator and redis-operator
  - All operators can be deployed at once using `kubectl apply -k operators/`
  - Separate operators can be deployed using e.g. `kubectl apply -k operators/redis/`
- `postgres`
  - Contains CR `postgresql` - postgresql cluster with basic configuration
  - Postgres-operator has to be installed first, and then it can be installed by `kubectl apply -k postgres/`
- `redis`
  - Contains CR `RedisFailover` - redis sentinel with basic configuration
  - Redis-operator has to be installed first, and then it can be installed by `kubectl apply -k redis/`
- `envs`
  - Contains kustomize overlays, e.g. `envs/public/`
  - Each subdirectory define deployment of Harbor
    - refers to `base`
    - adds *harbor-config* configmap
    - It can contain patches and other kustomizations, like `envs/public/redis/`

## Installation

### Prerequisites

#### Kubernetes v1.20+
```
export KUBECONFIG=/path/to/kubeconfig
```

#### FluxCD
```
curl -s https://fluxcd.io/install.sh | sudo FLUX_VERSION=0.40.2 bash
flux install
```

### Example installation - public environment

#### Install and wait for operators
```
$ kubectl apply -k operators/
$ flux get helmrelease -n default
NAME                    REVISION        SUSPENDED       READY   MESSAGE
cert-manager            v1.11.0         False           True    Release reconciliation succeeded
ingress-nginx           4.5.2           False           True    Release reconciliation succeeded
postgres-operator       1.9.0           False           True    Release reconciliation succeeded
redis-operator          3.2.7           False           True    Release reconciliation succeeded
```

> Note: Install separate operators by e.g.:
> ```
> kubectl apply -k operators/redis/
> kubectl apply -k operators/postgres/
> ```

#### Create redis and postgres cluster
```
bash envs/public/redis/redis-secret.bash
kubectl apply -k envs/public/redis/
kubectl apply -k envs/public/postgres/
```

#### Install Harbor

- Take *ingress-nginx-controller* LoadBalancer IP address and create DNS record for Harbor.

- Generate secrets and install Harbor:
  ```
  bash envs/public/harbor-secrets.bash
  bash envs/public/swift-secret.bash <username> <password>
  kubectl apply -k envs/public/
  ```

#### All in one installation using FluxCD Kustomization and GitRepository reconciliation

```
bash envs/public/redis/redis-secret.bash
bash envs/public/harbor-secrets.bash
bash envs/public/swift-secret.bash <username> <password>
# --branch/tag can be specified, default to master
flux create source git k8s-harbor --url=https://github.com/SovereignCloudStack/k8s-harbor --interval=5m
kubectl apply -f envs/public/public.yaml
```

## Automated smoke tests

In order to ensure that every component inside of SCS behaves as
expected, there should be simple smoke tests.
These tests are implemented using GitHub Actions/Workflows.

## References

|               |                                                                                         |
|---------------|-----------------------------------------------------------------------------------------|
| CI smoke test | ![Smoke test](https://github.com/SovereignCloudStack/k8s-harbor/workflows/CI/badge.svg) |

## Further information

Harbor website: https://goharbor.io/
