#!/bin/bash

set -euo pipefail
dir_path=$(dirname $(realpath $0))

NAMESPACE=apicurio-registry

# keycloak realm
kubectl -n $NAMESPACE delete -f $dir_path/realm.yaml

# keycloak instance
kubectl -n $NAMESPACE delete -f $dir_path/keycloak.yaml

# keycloak operator
kustomize build $dir_path/install/ | kubectl delete -f -
