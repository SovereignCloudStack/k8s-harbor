# SCS deployment

The following steps were utilized for deploying the SCS reference installation of the Harbor container registry,
which is available at https://registry.scs.community.

## Prerequisites

- Kubernetes cluster v1.20+
  - We used the R5 version of SCS KaaS V1, which includes an ingress controller and cert manager
    ```bash
    export KUBECONFIG=/path/to/kubeconfig
    ```
- Flux CLI (it is part of SCS KaaS V1)
  - Installation documentation: https://fluxcd.io/flux/installation/#install-the-flux-cli
    ```bash
    curl -s https://fluxcd.io/install.sh | sudo FLUX_VERSION=2.2.3 bash
    flux install
    ```
- [kubectl](https://kubernetes.io/docs/reference/kubectl/)

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
  envs/public/s3-credentials.bash <accesskey> <secretkey>
  kubectl apply -k envs/public/
  ```
