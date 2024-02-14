# Quickstart

This guide shows you how to set up a working Harbor Container Registry that utilizes a Kubernetes cluster.

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
    
## Install Harbor container registry

Apply kustomization manifest in `envs/dev` directory:
```bash
kubectl apply -k envs/dev/
```

Port-forward the Harbor container registry service:
```bash
kubectl port-forward svc/harbor 8080:80
```
Access the Harbor container registry UI and use Harbor's default credentials 
- username: `admin`
- password: `Harbor12345`

```bash
http://localhost:8080
```
