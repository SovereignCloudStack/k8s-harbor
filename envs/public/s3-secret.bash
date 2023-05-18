#!/bin/bash

if test $# -lt 2; then
  echo "Missing S3 accesskey and secretkey"
  exit 1
fi

kubectl create secret generic s3-secret \
  --from-literal=accesskey="$1" \
  --from-literal=secretkey="$2" \
  -n "${3:-default}"
