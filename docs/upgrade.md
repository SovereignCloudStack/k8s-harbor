# Upgrade

This page aims at providing additional information for upgrading [Harbor](https://goharbor.io/)
container registry, which operates in the Kubernetes environment and is deployed with Helm.
It extends the official [Upgrading Harbor Deployed with Helm page](https://goharbor.io/docs/main/administration/upgrade/helm-upgrade/),
where the upgrade process is well described. See the following upgrade hints:

- Always [backup](backup_and_restore) your Harbor instance before upgrade
- Normally Harbor helm upgrade from 2 minor versions lower should be [tested](https://github.com/goharbor/harbor-helm/issues/500#issuecomment-647029797), but always
  validate your planned upgrade path with recommendations in the official [docs](https://goharbor.io/docs/main/administration/upgrade/).
- The step-by-step upgrade is needed because of possible DDL changes in the Harbor database.
  Harbor core service executes the [migrations scripts](https://github.com/goharbor/harbor/tree/main/make/migrations/postgresql) automatically.
  The helm upgrade process may fail in the case of the failure of migration scripts. 
  Hence, it is a good idea to run migration scripts with a pre-upgrade job. Harbor Helm
  has an option `enableMigrateHelmHook` which separates the database migration from Harbor core
  and runs the migration job as a pre-upgrade hook.
