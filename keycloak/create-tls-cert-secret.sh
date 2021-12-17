#!/bin/bash

set -euo pipefail
dir_path=$(dirname $(realpath $0))

NAMESPACE=apicurio-registry
KEYCLOAK_DOMAIN=keycloak-$NAMESPACE.apps.dev-eng-ocp4-8.dev.3sca.net

echo -n | openssl s_client -connect $KEYCLOAK_DOMAIN:443 -servername $KEYCLOAK_DOMAIN --showcerts | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /tmp/keycloak.crt
kubectl -n $NAMESPACE create configmap keycloak-tls-cert-ext --from-file=/tmp/keycloak.crt
rm -rf /tmp/keycloak.crt
