#!/bin/bash

REDIS_PASS="$(pwgen -s 20 1)"

kubectl create secret generic harbor-redis-auth \
  --from-literal=password="$REDIS_PASS" \
  --from-literal=REDIS_PASSWORD="$REDIS_PASS" \
  -n "${1:-default}"
