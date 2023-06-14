#!/bin/bash

if test $# -lt 2; then
  echo "Missing S3 accesskey and secretkey"
  exit 1
fi

kubectl create secret generic s3-credentials \
  --from-literal=REGISTRY_STORAGE_S3_ACCESSKEY="$1" \
  --from-literal=REGISTRY_STORAGE_S3_SECRETKEY="$2" \
  -n "${3:-default}"
