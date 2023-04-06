# Deployment manifests for Harbor

## Repository content

This repository is intended to include all relevant configuration
and Kubernetes manifests for the deployment of Harbor inside SCS.

## Repository layout

This repository contains kustomize bases which may be referenced by
kustomize overlays which in turn define the deployment of whole
environments/clusters.

Also, usually flux2 resources are used for e.g. Helm, so flux2 controllers need to be installed in any destination cluster.

## Installation

### Prerequisites

#### Fluxcd
```
curl -s https://fluxcd.io/install.sh | sudo FLUX_VERSION=0.40.2 bash
flux install
```

### Install and wait for operators
```
$ k apply -k operators/
$ flux get helmrelease -n default
NAME                    REVISION        SUSPENDED       READY   MESSAGE
cert-manager            v1.11.0         False           True    Release reconciliation succeeded
ingress-nginx           4.5.2           False           True    Release reconciliation succeeded
postgres-operator       1.9.0           False           True    Release reconciliation succeeded
redis-operator          3.2.7           False           True    Release reconciliation succeeded
```

Install separate operator by  e.g. `k apply -k operators/postgres/`

### Create redis and postgres cluster
```
bash envs/public/redis-secret.bash
k apply -k redis/
k apply -k postgres/
```

### Install Harbor

Take *ingress-nginx-controller* loadbalancer IP address and create DNS record for Harbor.

Generate secrets and install Harbor:
```
bash envs/public/harbor-secrets.bash
bash envs/public/swift-secret.bash <username> <password>
k apply -k envs/public/
```

### All in one installation using fluxcd Kustomization and GitRepository reconciliation

```
bash envs/public/redis-secret.bash
bash envs/public/harbor-secrets.bash
#bash envs/public/swift-secret.bash <username> <password>
# --branch/tag can be specified, default to master
flux create source git k8s-harbor --url=https://github.com/SovereignCloudStack/k8s-harbor --interval=5m
k apply -f envs/public/public.yaml
```

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


