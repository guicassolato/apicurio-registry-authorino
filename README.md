# Protecting Apicurio Registry with Authorino (on OpenShift)

## Instructions

### 1. Setup

#### Clone the repo ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$git%20clone%20git@github.com:guicassolato/apicurio-registry-authorino%20&&%20cd%20apicurio-registry-authorino))

```sh
git clone git@github.com:guicassolato/apicurio-registry-authorino && cd apicurio-registry-authorino
```

#### Set the kube context ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$oc%20login%20--token=<token>%20--server=https://api.dev-eng-ocp4-8.dev.3sca.net:6443))

```sh
oc login --token=<token> --server=https://api.dev-eng-ocp4-8.dev.3sca.net:6443
```

#### Create the namespace ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$kubectl%20create%20namespace%20apicurio-registry))

```sh
kubectl create namespace apicurio-registry
```

### 2. Install Apicurio Registry

#### Install the Apicurio Registry database ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$kubectl%20-n%20apicurio-registry%20apply%20-f%20apicurio-registry-database.yaml))

```sh
kubectl -n apicurio-registry apply -f apicurio-registry-database.yaml
```

#### Install Apicurio Registry ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$kubectl%20-n%20apicurio-registry%20apply%20-f%20apicurio-registry.yaml))

```sh
kubectl -n apicurio-registry apply -f apicurio-registry.yaml
```

#### Try Apicurio Registry without protection ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$firefox%20--private-window%20https://apicurio-registry-unprotected.apps.dev-eng-ocp4-8.dev.3sca.net))

```sh
firefox --private-window https://apicurio-registry-unprotected.apps.dev-eng-ocp4-8.dev.3sca.net
```

### 3. Install Keycloak

#### Install Keycloak ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$./keycloak/install.sh))

```sh
./keycloak/install.sh
```

#### Store Keycloak TLS certificate ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$./keycloak/create-tls-cert-secret.sh))

```sh
./keycloak/create-tls-cert-secret.sh
```

### 4. Install Authorino

#### Install the Authorino Operator ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$kubectl%20apply%20-f%20https://raw.githubusercontent.com/Kuadrant/authorino-operator/main/config/deploy/manifests.yaml))

```sh
kubectl apply -f https://raw.githubusercontent.com/Kuadrant/authorino-operator/main/config/deploy/manifests.yaml
```

#### Deploy Authorino ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$kubectl%20-n%20apicurio-registry%20apply%20-f%20authorino.yaml))

```sh
kubectl -n apicurio-registry apply -f authorino.yaml
```

#### Add Keycloak TLS certificate to Authorio trusted certificate chain ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$kubectl%20-n%20authorino-operator%20scale%20--replicas=0%20$(kubectl%20-n%20authorino-operator%20get%20deployments%20-l%20control-plane=controller-manager%20-o%20name)%0Akubectl%20-n%20apicurio-registry%20patch%20deployment%20authorino%20--type=strategic%20--patch%20%22$(cat%20keycloak-cert-patch.yaml)%22))

```sh
kubectl -n authorino-operator scale --replicas=0 $(kubectl -n authorino-operator get deployments -l control-plane=controller-manager -o name)
kubectl -n apicurio-registry patch deployment authorino --type=strategic --patch "$(cat keycloak-cert-patch.yaml)"
```

The command above will scale the Authorino Operator down to zero. This will not be neeed once the operator can provide support for injecting TLS certificates in the chain of trusted certificates of the Authorino containers.

#### Deploy Envoy ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$kubectl%20-n%20apicurio-registry%20apply%20-f%20envoy.yaml))

```sh
kubectl -n apicurio-registry apply -f envoy.yaml
```

#### Try Apicurio Registry protected with Envoy and Authorino ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$firefox%20--private-window%20https://apicurio-registry.apps.dev-eng-ocp4-8.dev.3sca.net))

```sh
firefox --private-window https://apicurio-registry.apps.dev-eng-ocp4-8.dev.3sca.net
```

Authenticate in Keycloak with any of the user credentials provided:

- **Admin user**<br/>
    Username: registry-admin<br/>
    Password: changeme<br/>
- **API developer**<br/>
    Username: registry-developer<br/>
    Password: changeme<br/>
- **API user**<br/>
    Username: registry-user<br/>
    Password: changeme<br/>

Using Keycloak Account Management to sign out will not work. This is because the Keycloak-issued access token remains valid. ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$firefox%20--private-window%20https://keycloak-apicurio-registry.apps.dev-eng-ocp4-8.dev.3sca.net/auth/realms/apicurio-registry/account))

```sh
firefox --private-window https://keycloak-apicurio-registry.apps.dev-eng-ocp4-8.dev.3sca.net/auth/realms/apicurio-registry/account
```

To sign out, use the Envoy-provided endpoint: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$firefox%20--private-window%20https://apicurio-registry.apps.dev-eng-ocp4-8.dev.3sca.net/signout))

```sh
firefox --private-window https://apicurio-registry.apps.dev-eng-ocp4-8.dev.3sca.net/signout
```

### 5. Add the AuthConfig

#### Create the `AuthConfig` ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$kubectl%20-n%20apicurio-registry%20apply%20-f%20authconfig.yaml))

```sh
kubectl -n apicurio-registry apply -f authconfig.yaml
```

#### Try Apicurio Registry with access control

- All users can read/create/update artifacts.
- Only users with the `sr-admin` role can delete artifacts.
