# Container registry HA deployment

## Prerequisites

- Kubernetes cluster v1.20+
  - Use existing cluster
    ```bash
    export KUBECONFIG=/path/to/kubeconfig
    ```
  - Alternatively, spawn some dev cluster, e.g. using [KinD](https://kind.sigs.k8s.io/docs/user/quick-start/)
    ```bash
    kind create cluster
    ```
- Flux CLI
  - Installation documentation: https://fluxcd.io/flux/installation/#install-the-flux-cli
    ```bash
    curl -s https://fluxcd.io/install.sh | sudo FLUX_VERSION=2.2.3 bash
    flux install
    ```
    
## Install and wait for operators

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

## Create redis and postgres clusters

```
envs/public-ha/redis/redis-secret.bash # pwgen needs to be installed
kubectl apply -k envs/public-ha/redis/
kubectl apply -k envs/public-ha/postgres/
```

## Install Harbor

- Take *ingress-nginx-controller* LoadBalancer IP address and create DNS record for Harbor.
  ```
  kubectl get svc -n ingress-nginx
  NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
  ingress-nginx-controller             LoadBalancer   100.92.14.168   81.163.194.219   80:30799/TCP,443:32482/TCP   2m51s
  ingress-nginx-controller-admission   ClusterIP      100.88.40.231   <none>           443/TCP                      2m51s
  ```

- Generate secrets and install Harbor:
  ```
  base/harbor-secrets.bash # pwgen and htpasswd need to be installed
  envs/public-ha/swift-secret.bash <username> <password>
  kubectl apply -k envs/public-ha/
  ```

## All in one installation using FluxCD Kustomization and GitRepository reconciliation

```
envs/public-ha/redis/redis-secret.bash
base/harbor-secrets.bash
envs/public-ha/swift-secret.bash <username> <password>
# --branch/tag can be specified, default to master
flux create source git k8s-harbor --url=https://github.com/SovereignCloudStack/k8s-harbor --interval=5m
kubectl apply -f envs/public-ha/public-ha.yaml
```
