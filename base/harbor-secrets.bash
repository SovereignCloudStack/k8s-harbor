#!/bin/bash

FILE=$(mktemp ./values.yaml.XXXXXX)

REGISTRY_USER=harbor
REGISTRY_PASSWD="$(pwgen -s 20 1)"
REGISTRY_HTPASSWD="$(htpasswd -nbBC10 "$REGISTRY_USER" "$REGISTRY_PASSWD")"

cat > "$FILE" <<EOF
harborAdminPassword: '$(pwgen -s 20 1)'
secretKey: '$(pwgen -s 16 1)'
core:
  secret: '$(pwgen -s 16 1)'
  xsrfKey: '$(pwgen -s 32 1)'
jobservice:
  secret: '$(pwgen -s 16 1)'
registry:
  secret: '$(pwgen -s 16 1)'
  credentials:
    username: $REGISTRY_USER
    password: '$REGISTRY_PASSWD'
    htpasswdString: '$REGISTRY_HTPASSWD'
EOF

kubectl create secret generic harbor-secrets --from-file=values.yaml="$FILE"
