#!/bin/bash

FILE=$(mktemp ./values.yaml.XXXXXX)

cat > $FILE <<EOF
harborAdminPassword: $(pwgen -s 20 1)
secretKey: $(pwgen -s 16 1)
core:
  secret: $(pwgen -s 16 1)
  xsrfKey: $(pwgen -s 32 1)
jobservice:
  secret: $(pwgen -s 16 1)
registry:
  secret: $(pwgen -s 16 1)
EOF

kubectl create secret generic harbor-secrets --from-file=values.yaml=$FILE
