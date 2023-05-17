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

### Example public HA environment installation

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

#### Create redis and postgres clusters
```
bash envs/public-ha/redis/redis-secret.bash
kubectl apply -k envs/public-ha/redis/
kubectl apply -k envs/public-ha/postgres/
```

#### Install Harbor

- Take *ingress-nginx-controller* LoadBalancer IP address and create DNS record for Harbor.
  ```
  kubectl get svc -n ingress-nginx
  NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
  ingress-nginx-controller             LoadBalancer   100.92.14.168   81.163.194.219   80:30799/TCP,443:32482/TCP   2m51s
  ingress-nginx-controller-admission   ClusterIP      100.88.40.231   <none>           443/TCP                      2m51s
  ```

- Generate secrets and install Harbor:
  ```
  bash base/harbor-secrets.bash
  bash envs/public-ha/swift-secret.bash <username> <password>
  kubectl apply -k envs/public-ha/
  ```

#### All in one installation using FluxCD Kustomization and GitRepository reconciliation

```
bash envs/public-ha/redis/redis-secret.bash
bash base/harbor-secrets.bash
bash envs/public-ha/swift-secret.bash <username> <password>
# --branch/tag can be specified, default to master
flux create source git k8s-harbor --url=https://github.com/SovereignCloudStack/k8s-harbor --interval=5m
kubectl apply -f envs/public-ha/public-ha.yaml
```

### Public environment threat model

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

## References

|               |                                                                                         |
|---------------|-----------------------------------------------------------------------------------------|
| CI smoke test | ![Smoke test](https://github.com/SovereignCloudStack/k8s-harbor/workflows/CI/badge.svg) |

## Further information

Harbor website: https://goharbor.io/
