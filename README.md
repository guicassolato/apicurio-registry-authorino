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

Keycloak's TLS public certificate will be mounted from this ConfigMap into the chain of trusted certificates of the Authorino pod.

### 4. Install Authorino

#### Install the Authorino Operator ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$curl%20-sSl%20https://raw.githubusercontent.com/Kuadrant/authorino-operator/volumes/config/deploy/manifests.yaml%20%7C%20sed%20's/quay.io%5C/3scale%5C/authorino-operator:v0.0.1/quay.io%5C/guicassolato%5C/authorino:operator-pr20/g'%20%7C%20kubectl%20apply%20-f%20-))

```sh
curl -sSl https://raw.githubusercontent.com/Kuadrant/authorino-operator/volumes/config/deploy/manifests.yaml | sed 's/quay.io\/3scale\/authorino-operator:v0.0.1/quay.io\/guicassolato\/authorino:operator-pr20/g' | kubectl apply -f -
```

#### Deploy Authorino ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$kubectl%20-n%20apicurio-registry%20apply%20-f%20authorino.yaml))

```sh
kubectl -n apicurio-registry apply -f authorino.yaml
```

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

To sign out, close the session in Keycloak Account Management: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$firefox%20--private-window%20https://keycloak-apicurio-registry.apps.dev-eng-ocp4-8.dev.3sca.net/auth/realms/apicurio-registry/account))

```sh
firefox --private-window https://keycloak-apicurio-registry.apps.dev-eng-ocp4-8.dev.3sca.net/auth/realms/apicurio-registry/account
```

...or by navigating to the logout endpoint: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$firefox%20--private-window%20https://keycloak-apicurio-registry.apps.dev-eng-ocp4-8.dev.3sca.net/auth/realms/apicurio-registry/protocol/openid-connect/logout))

```sh
firefox --private-window https://keycloak-apicurio-registry.apps.dev-eng-ocp4-8.dev.3sca.net/auth/realms/apicurio-registry/protocol/openid-connect/logout
```

...and use the Envoy-provided endpoint that clears the authentication cookies in application: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$firefox%20--private-window%20https://apicurio-registry.apps.dev-eng-ocp4-8.dev.3sca.net/signout))

```sh
firefox --private-window https://apicurio-registry.apps.dev-eng-ocp4-8.dev.3sca.net/signout
```

### 5. Add the AuthConfig

#### Create the `AuthConfig` ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=newTerminal$$kubectl%20-n%20apicurio-registry%20apply%20-f%20authconfig.yaml))

```sh
kubectl -n apicurio-registry apply -f authconfig.yaml
```

#### Try Apicurio Registry with access control

Authorino will apply the same R/W permissions otherwise enforced by Apicurio Registry's built-in authorization based on the user roles:

| API       | Method   | Path                                                                  | Permission |
| --------- | -------- | --------------------------------------------------------------------- |:----------:|
| Artifacts | `GET`    | /apis/registry/v2/groups/default/artifacts                            | Read       |
| Artifacts | `POST`   | /apis/registry/v2/groups/default/artifacts                            | Write      |
| Artifacts | `GET`    | /apis/registry/v2/groups/default/artifacts/{aid}                      | Read       |
| Artifacts | `PUT`    | /apis/registry/v2/groups/default/artifacts/{aid}                      | Write      |
| Artifacts | `DELETE` | /apis/registry/v2/groups/default/artifacts/{aid}                      | Write      |
| Artifacts | `PUT`    | /apis/registry/v2/groups/default/artifacts/{aid}/state                | Write      |
| Artifacts | `GET`    | /apis/registry/v2/groups/default/artifacts/{aid}/meta                 | Read       |
| Artifacts | `PUT`    | /apis/registry/v2/groups/default/artifacts/{aid}/meta                 | Write      |
| Artifacts | `POST`   | /apis/registry/v2/groups/default/artifacts/{aid}/meta                 | Read       |
| Artifacts | `GET`    | /apis/registry/v2/groups/default/artifacts/{aid}/versions             | Read       |
| Artifacts | `POST`   | /apis/registry/v2/groups/default/artifacts/{aid}/versions             | Write      |
| Artifacts | `GET`    | /apis/registry/v2/groups/default/artifacts/{aid}/versions/{vid}       | Read       |
| Artifacts | `PUT`    | /apis/registry/v2/groups/default/artifacts/{aid}/versions/{vid}/state | Write      |
| Artifacts | `GET`    | /apis/registry/v2/groups/default/artifacts/{aid}/versions/{vid}/meta  | Read       |
| Artifacts | `PUT`    | /apis/registry/v2/groups/default/artifacts/{aid}/versions/{vid}/meta  | Write      |
| Artifacts | `DELETE` | /apis/registry/v2/groups/default/artifacts/{aid}/versions/{vid}/meta  | Write      |
| Artifacts | `GET`    | /apis/registry/v2/groups/default/artifacts/{aid}/rules                | Read       |
| Artifacts | `POST`   | /apis/registry/v2/groups/default/artifacts/{aid}/rules                | Write      |
| Artifacts | `DELETE` | /apis/registry/v2/groups/default/artifacts/{aid}/rules                | Write      |
| Artifacts | `GET`    | /apis/registry/v2/groups/default/artifacts/{aid}/rules/{rid}          | Read       |
| Artifacts | `PUT`    | /apis/registry/v2/groups/default/artifacts/{aid}/rules/{rid}          | Write      |
| Artifacts | `DELETE` | /apis/registry/v2/groups/default/artifacts/{aid}/rules/{rid}          | Write      |
| Artifacts | `PUT`    | /apis/registry/v2/groups/default/artifacts/{aid}/test                 | Read       |
| GlobalIds | `GET`    | /apis/registry/v2/ids/{id}                                            | Read       |
| GlobalIds | `GET`    | /apis/registry/v2/ids/{id}/meta                                       | Read       |
| Rules     | `GET`    | /apis/registry/v2/admin/rules                                         | Admin      |
| Rules     | `POST`   | /apis/registry/v2/admin/rules                                         | Admin      |
| Rules     | `GET`    | /apis/registry/v2/admin/rules/{rid}                                   | Admin      |
| Rules     | `PUT`    | /apis/registry/v2/admin/rules/{rid}                                   | Admin      |
| Rules     | `DELETE` | /apis/registry/v2/admin/rules/{rid}                                   | Admin      |
| Rules     | `DELETE` | /apis/registry/v2/admin/rules                                         | Admin      |
| Search    | `GET`    | /apis/registry/v2/search/artifacts                                    | Read       |
| Search    | `GET`    | /apis/registry/v2/search/artifacts/{aid}/versions                     | Read       |
