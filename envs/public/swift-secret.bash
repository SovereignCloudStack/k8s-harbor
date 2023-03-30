#!/bin/bash

if test -z "$1"; then
  echo "Missing Swift password"
  exit 1
fi

kubectl create secret generic swift-secret --from-literal=password="$1"
