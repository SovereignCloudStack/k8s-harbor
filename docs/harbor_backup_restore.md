# Harbor - backup and restore

This page aims at providing a step-by-step guide for backup and restore [Harbor](https://goharbor.io/)
container registry using [Velero](https://velero.io/) tool.
It extends the official [Harbor backup-restore docs page](https://goharbor.io/docs/main/administration/backup-restore/)
with up-to-date commands, explanations, and an extensive prerequisites section. This
guide references and uses Velero in [v1.10.2](https://github.com/vmware-tanzu/velero/releases/tag/v1.10.2)
as this is the latest stable version at the time of writing this guide.

It provides guidance and commands that readers are encouraged to try out by themselves
on Harbor deployment as described in the next sections. It does not aim at providing an
exhaustive list of commands nor all the possible ways how to use them.

The guide covers two strategies to save Harbor data:
- Backup: a regular backup created by the [restic](https://restic.net/) integration in Velero as described in the related [docs](https://velero.io/docs/main/file-system-backup/)
- Snapshot: a point-in-time snapshot be the Container Storage Interface (CSI) snapshot support in Velero as described in the related [docs](https://velero.io/docs/main/csi/)

Before you choose the right strategy for your Harbor deployment back up make sure that you understand
[differences](https://www.terra-master.com/global/snapshot) between the backup and snapshot.
In general, for long-term protection of Harbor data, you may use backup and for
temporary protection of data (e.g. before Harbor upgrade) you may use snapshot.

Note that this guide is not limited to Harbor deployments that utilize SCS environments,
but it is required to have a set of tools and services (e.g. Kubernetes CSI plugin with volume snapshot
support, S3 compatible object store for backups) for successful backup and restore procedure
(see the [prerequisites](#prerequisites-) section). These tools and services come out of
the box when the SCS infrastructure and KaaS is used for Harbor deployment, hence it is
convenient to use them. 

## Prerequisites 

### Kubernetes cluster

If you want to use `snapshot` to back up Harbor data ensure the following:
- Your cluster is Kubernetes version 1.20 or greater
- Your cluster is running a [CSI driver](https://kubernetes-csi.github.io/docs/drivers.html)
  capable of support volume snapshots at the [v1 API level](https://kubernetes.io/blog/2020/12/10/kubernetes-1.20-volume-snapshot-moves-to-ga/).
  To enable creating volume snapshots the [snapshot-controller](https://kubernetes-csi.github.io/docs/snapshot-controller.html)
  and its CRDs should be deployed in the Kubernetes cluster as well. The snapshot-controller
  is independent of any CSI Driver. These prerequisites come out of the box with the SCS KaaS solution.

If you want to create Harbor `backup` ensure the following:  
- Your cluster is Kubernetes version 1.16 or greater

If your cluster meets the above, export its kubeconfig path in env. variable `KUBECONFIG`:
```bash
export KUBECONFIG=/path/to/kubeconfig
```

### S3 bucket and EC2 credentials

This guide assumes that the public cloud's object store with S3-compatible API is available as
the storage backend for Velero. In this guide, we are using OpenStack Swift which 
offers S3-compatible API. Let's create an S3 bucket on Swift object storage and EC2 credentials
that will be later used by Velero.

You should have access to your OpenStack project, and the OpenStack RC file that contains access 
values. Set the environment variables by sourcing the OpenStack RC file:

```bash
source <project>-openrc.sh
```

Swift object store service does not support application credentials authentication
to access S3 API. To authenticate in S3 API, you should generate and use the EC2 credentials
mechanism. You can generate EC2 credentials as follows:

```bash
$ openstack ec2 credentials create
+------------+----------------------------------------------------------------------------------------------------------+
| Field      | Value                                                                                                    |
+------------+----------------------------------------------------------------------------------------------------------+
| access     | <aws_access_key_id>                                                                                      |
| links      | {'self': 'https://api.gx-scs.sovereignit.cloud:5000/v3/users/<user_id>/credentials/OS-EC2/<project_id>'} |
| project_id | <project_id>                                                                                             |
| secret     | <aws_secret_access_key>                                                                                  |
| trust_id   | None                                                                                                     |
| user_id    | <user_id>                                                                                                |
+------------+----------------------------------------------------------------------------------------------------------+
```

Write down `aws_access_key_id` and `aws_secret_access_key` values from the output of `openstack ec2 credentials create`
command and store them in the `~/.aws/credentials` file as follows:

```bash
mkdir ~/.aws
cat >~/.aws/credentials <<EOF
[default]
aws_access_key_id = <aws_access_key_id>
aws_secret_access_key = <aws_secret_access_key>
EOF
```

This credential file is then used as an access and secret source for AWS CLI tool and also
as a source for Velero. If your environment does not have AWS CLI installed, install it as follows:

```bash
pip3 install awscli awscli-plugin-endpoint
```

Finally, create a new bucket. Note that the following command contains `endpoint-url`
argument that points AWS CLI to the GX-SCS OpenStack Swift object store API.

```bash
aws --endpoint-url https://api.gx-scs.sovereignit.cloud:8080 s3 mb s3://velero-backup
```

### Velero client

In this guide, we are using [Velero](https://velero.io/) to back up and restore a Harbor instance. 
Velero is an open source tool to safely back up and restore, perform disaster recovery,
and migrate Kubernetes cluster resources.

Go through the [official docs](https://velero.io/docs/main/basic-install/) and 
install the Velero client on your desired environment. If your environment is Linux distribution
you can use the following steps and install the Velero client from the source:

```bash
wget https://github.com/vmware-tanzu/velero/releases/download/v1.10.2/velero-v1.10.2-linux-amd64.tar.gz 
tar -zxvf velero-v1.10.2-linux-amd64.tar.gz 
sudo mv velero-v1.10.2-linux-amd64/velero /usr/local/bin/
```

### Velero server

Install Velero server components along with the appropriate plugins, into the Kubernetes cluster. 
This will create a namespace called `velero`, and place a deployment named `velero` in it.
Note that the installation command sets the bucket `velero-backup` that has been created a few steps 
earlier as well as EC2 credentials located in `~/.aws/credentials` file. Also note that 
the `region` and `s3Url` parameters are GX-SCS specific. For further details about installation
options, supported storage providers, and more visit the official Velero [docs](https://velero.io/docs/).

- If you want to use `snapshot` to back up Harbor data:
  - Install Velero:
  ```bash
   velero install \
     --features=EnableCSI \
     --provider aws \
     --plugins velero/velero-plugin-for-aws:v1.6.1,velero/velero-plugin-for-csi:v0.4.2 \
     --bucket velero-backup \
     --secret-file ~/.aws/credentials \
     --backup-location-config region=RegionOne,s3ForcePathStyle="true",s3Url=https://api.gx-scs.sovereignit.cloud:8080 \
     --snapshot-location-config region=RegionOne,enableSharedConfig=true
   ```
   - In order to allow Velero to do Volume Snapshots, we need to deploy a new VolumeSnapshotClass. Create a velero-snapclass.yaml file as follows:
  ```bash
  cat > velero-snapclass.yaml << EOF
  apiVersion: snapshot.storage.k8s.io/v1
  deletionPolicy: Delete
  driver: cinder.csi.openstack.org
  kind: VolumeSnapshotClass
  metadata:
    name: csi-cinder-snapclass-in-use-v1-velero
    labels:
      velero.io/csi-volumesnapshot-class: "true"
  parameters:
    force-create: "true"
  EOF
  ```
  - Apply the new class:
  ```bash
  kubectl apply -f velero-snapclass.yaml
  ```
- If you want to create Harbor `backup` with Restic: 
  - Install Velero:
  ```bash
  velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.6.1 \
    --bucket velero-backup \
    --secret-file ~/.aws/credentials \
    --use-volume-snapshots=false \
    --uploader-type=restic \
    --use-node-agent \
    --backup-location-config region=RegionOne,s3ForcePathStyle="true",s3Url=https://api.gx-scs.sovereignit.cloud:8080
  ```

##  Backup and restore

Note that the following backup steps mainly point to actions from an official [Backup And Restore Harbor With Velero](https://goharbor.io/docs/main/administration/backup-restore) tutorial.
In this guide, find the added value from additional explanations/hints and up-to-date commands.

Harbor, by design, consists of multiple (micro)services that could store their data
variously, based on the Harbor configuration. See the [Harbor persistence](harbor_persistence.md)
docs for further information regarding the Harbor persistence layer. The following steps cover
cases when Harbor persistence is enabled and the "internal" databases (PostgreSQL and Redis)
are used.

Note that backups of external databases (PostgreSQL and Redis) are not supported by the 
official tutorial and are out of the scope of this guide as well.
Also, keep an eye on the official backup and restore [limitations](https://goharbor.io/docs/main/administration/backup-restore/#limitations)
section to be aware of the potential impact on your Harbor instance. The limitation:
`The upload purging process may cause backup failure` mentioned that it is better to
increase registry upload purging interval (it is a background process that periodically
removes orphaned files from the upload directories of the registry, see the [docs](https://docs.docker.com/registry/configuration/#uploadpurging)).
This interval is by [default](https://github.com/goharbor/harbor-helm/blob/master/values.yaml#L598)
set to 24h (helm value: `registry.upload_purging.interval`). If you do not want to change
the registry configuration at all you should ensure that the backup will be performed in
the middle of two rounds of purging. This background process starts when the registry
container is initialized, therefore is a good idea to check logs of the registry container
and determine when is a good time to do a backup, e.g. as follows:
```bash
$ kubectl logs -l component=registry -c registry --tail -1 | grep -i purge
time="2023-04-17T09:02:08.320514706Z" level=info msg="Starting upload purge in 24h0m0s" go.version=go1.15.6 instance.id=xxx service=registry version=v2.7.1.m 
time="2023-04-17T09:09:08.321004645Z" level=info msg="PurgeUploads starting: olderThan=2023-04-10 09:09:08.320738572 +0000 UTC m=-604379.969424455, actuallyDelete=true" 
time="2023-04-17T09:09:08.331433127Z" level=info msg="Purge uploads finished.  Num deleted=0, num errors=0" 
...
```

### Backup Harbor Instance

1. [Set Harbor to the `ReadOnly` mode](https://goharbor.io/docs/main/administration/backup-restore/#set-harbor-to-readonly)

2. Backup Harbor:
   - Using `snapshot` to back up Harbor data:
     - Exclude the volume of Redis in backup, we need to label the Redis pod, PVC and PV with specific label:  
       ```bash
       # label the Pod of Redis, replace the namespace and Pod name with yours
        kubectl -n default label pod/harbor-harbor-redis-0 velero.io/exclude-from-backup=true
        # label the PVC of Redis, replace the namespace and PVC name with yours
        kubectl -n default label pvc/data-harbor-harbor-redis-0 velero.io/exclude-from-backup=true
        # get the name of Redis PV, replace the namespace and PVC name with yours
        kubectl -n default get pvc data-harbor-harbor-redis-0 --template={{.spec.volumeName}}
        # label the PV of Redis, replace the pv-name with the one get from last command
        kubectl label pv/pv-name velero.io/exclude-from-backup=true
       ```
     - Back up Harbor 
       ```bash
       # replace the namespace and backup name with yours
       velero backup create harbor-backup --include-namespaces default --snapshot-volumes --wait
       ```
   - Using `Restic` to back up Harbor data:
     - Exclude the volume of Redis in backup 
       ```bash
       # replace the namespace and pod name with yours
       kubectl -n default annotate pod/harbor-harbor-redis-0 backup.velero.io/backup-volumes-excludes=data
       ```
     - Back up Harbor 
       ```bash
       velero backup create harbor-backup --include-namespaces default --default-volumes-to-fs-backup --wait
       ```

3. [Unset Harbor from the `ReadOnly` mode](https://goharbor.io/docs/main/administration/backup-restore/#unset-readonly)

### Restore Harbor Instance

[Restore Harbor Instance](https://goharbor.io/docs/main/administration/backup-restore/#restore-harbor-instance)
