#!/bin/bash

if test $# -lt 2; then
  echo "Missing Swift username and password"
  exit 1
fi

kubectl create secret generic swift-secret \
  --from-literal=username="$1" \
  --from-literal=password="$2" \
  -n "${3:-default}"
