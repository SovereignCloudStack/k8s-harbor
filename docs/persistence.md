# Persistence

This page briefly describes and provides pointers on how Harbor persists data when it is
deployed in a Kubernetes cluster environment. It points out the default persistence settings
of [Harbor helm chart](https://github.com/goharbor/harbor-helm) as well as available options.

Harbor, by design, consists of multiple (micro)services that could store their data
variously, based on the Harbor configuration, see the [Architecture Overview of Harbor](https://github.com/goharbor/harbor/wiki/Architecture-Overview-of-Harbor).

## Data Access Layer

### Redis

- Usage
  - Key value storage used as a login session cache, a registry manifest cache, and a queue for the jobservice (e.g. see [Trivy](#-trivy)) 
- Default settings
  - Deployed as an "internal" single node database into the same Kubernetes cluster as Harbor (helm value: `redis.type.internal`)
  - Deployed as a StatefulSet with 1 replica
  - PV persistence is enabled by default (helm value: `persistence.enabled.true`), Redis POD mounts PV into the `/var/lib/redis` directory
- Additional settings
  - Harbor could be pointed to the "external" Redis (or Redis Sentinel) database (helm value: `redis.type.external`)
  - "Internal" Redis could be deployed without any persistence, i.e. it could use `emptyDir` (helm value: `persistence.enabled.false`)
- Notes
  - [What is the role of Redis in Harbor?](https://github.com/goharbor/harbor/issues/13544)
  - Redis data does not need to be backed up, see the [Limitations docs](https://goharbor.io/docs/main/administration/backup-restore/#limitations) for more details of the potential impact

### Database (PostgreSQL)

- Usage 
  - Stores the related metadata of Harbor models, like projects, users, roles, replication policies, tag retention policies, scanners, charts, and images
  - Could store [JobService](#jobservice) logs (helm value: `jobservice.jobLoggers.[database]`)
- Default settings
  - Deployed as an "internal" single node database into the same Kubernetes cluster as Harbor (helm value: `database.type.internal`)
  - Deployed as a StatefulSet with 1 replica
  - PV persistence is enabled by default (helm value: `persistence.enabled.true`), PostgreSQL POD mounts PV into the `/var/lib/postgresql/data` directory
- Additional settings
  - Harbor could be pointed to the "external" database (PostgreSQL) (helm value: `database.type.external`)
  - "Internal" database could be deployed without any persistence, i.e. it could use `emptyDir` (helm value: `persistence.enabled.false`)

### OCI Distribution Registry

- Usage 
  - Backend storage of container images and charts
- Default settings
  - Images and charts are stored in `registry` POD filesystem directory `/storage` (helm value: `persistence.imageChartStorage.type.filesystem`), this directory is mounted to the PV
- Additional settings
  - Various object storage backends: "azure", "gcs", "s3", "swift", "oss" (helm value: `persistence.imageChartStorage.type.<backend>`)
  - Backend storage could be`emptyDir` (helm value: `persistence.enabled.false`)

##  Fundamental Services

### Proxy, Core, Web Portal

- These Harbor services are stateless

### Trivy

- Usage  
  - A 3rd party vulnerability scanner provided by Aqua Security
- Default settings
  - Deployed as a StatefulSet with 1 replica
  - PV persistence is enabled by default (helm value: `persistence.enabled.true`), Trivy POD mounts PV into the `/home/scanner/.cache` directory
- Additional settings
  - Trivy could be deployed without any persistence, i.e. it could use `emptyDir` (helm value: `persistence.enabled.false`)
- Notes
  - [What kind of data are stored in /home/scanner/.cache?](https://github.com/aquasecurity/harbor-scanner-trivy/issues/135#issuecomment-671259649)

### JobService
- Usage  
  - General job execution queue service to let other components/services submit requests of running asynchronous tasks concurrently
- Default settings
  - Deployed as a Deployment with 1 replica
  - Store logs in the POD filesystem directory `/var/log/jobs` (helm value: `jobservice.jobLoggers.[file]`), this directory is mounted to the PV
- Additional settings
  - JobService could be deployed without any persistence, i.e. it could use `emptyDir` (helm value: `persistence.enabled.false`)
  - Logs could be stored in [Harbor database](#database-postgresql) (helm value: `jobservice.jobLoggers.[database]`) or just printed to the STDOUT (helm value: `jobservice.jobLoggers.[stdout]`)
