# Protecting Apicurio Registry with Authorino (on OpenShift)

## 1. Setup

### Clone the repo ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$git%20clone%20git@github.com:guicassolato/apicurio-registry-authorino%20&&%20cd%20apicurio-registry-authorino))

```sh
git clone git@github.com:guicassolato/apicurio-registry-authorino && cd apicurio-registry-authorino
```

### Set the context

Set the shell variables below to the session where you will all the commands: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAStringNoLF&text=demo$$OPENSHIFT_DOMAIN=%3Copenshift-domain%3E;%20OPENSHIFT_TOKEN=%3Ctoken%3E))

```sh
OPENSHIFT_DOMAIN=<openshift-domain>
OPENSHIFT_TOKEN=<token>
```

Log in to the OpenShift cluster and set the context for kubectl: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$oc%20login%20--token=$OPENSHIFT_TOKEN%20--server=https://api.$OPENSHIFT_DOMAIN:6443))

```sh
oc login --token=$OPENSHIFT_TOKEN --server=https://api.$OPENSHIFT_DOMAIN:6443
```

### (Optional) Make it easy to open Firefox from the terminal: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$alias%20firefox=%22$(which%20firefox)%22))

```sh
alias firefox="$(which firefox)"
```

### Create the namespace ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$kubectl%20create%20namespace%20apicurio-registry))

```sh
kubectl create namespace apicurio-registry
```

### (Optional) Watch the workload: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=workload$$watch%20-n%203%20%22kubectl%20get%20pods%20--all-namespaces%20%7C%20grep%20-E%20'apicurio-registry%7Cauthorino-operator%7Climitador-operator'%20%7C%20grep%20-viE%20'Completed%7COOMKilled'%22))

Watch the namespaces of interest in a separate terminal, to follow the state of your workload:

```sh
watch -n 3 "kubectl get pods --all-namespaces | grep -E 'apicurio-registry|authorino-operator|limitador-operator' | grep -viE 'Completed|OOMKilled'"
```

## 2. Install Apicurio Registry

### Install the Apicurio Registry database ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$kubectl%20-n%20apicurio-registry%20apply%20-f%20apicurio-registry-database.yaml))

```sh
kubectl -n apicurio-registry apply -f apicurio-registry-database.yaml
```

### Install Apicurio Registry ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$sed%20%22s/%5C$%7BOPENSHIFT_DOMAIN%7D/$OPENSHIFT_DOMAIN/g%22%20apicurio-registry.yaml%20%7C%20kubectl%20-n%20apicurio-registry%20apply%20-f%20-))

```sh
sed "s/\${OPENSHIFT_DOMAIN}/$OPENSHIFT_DOMAIN/g" apicurio-registry.yaml | kubectl -n apicurio-registry apply -f -
```

### Try Apicurio Registry without protection ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$firefox%20--private-window%20https://apicurio-registry-unprotected.apps.$OPENSHIFT_DOMAIN))

```sh
firefox --private-window https://apicurio-registry-unprotected.apps.$OPENSHIFT_DOMAIN
```

## 3. Install Keycloak

### Install Keycloak ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$OPENSHIFT_DOMAIN=$OPENSHIFT_DOMAIN%20./keycloak/install.sh))

```sh
OPENSHIFT_DOMAIN=$OPENSHIFT_DOMAIN ./keycloak/install.sh
```

### Store the Keycloak TLS certificate ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$OPENSHIFT_DOMAIN=$OPENSHIFT_DOMAIN%20./keycloak/create-tls-cert-secret.sh))

```sh
OPENSHIFT_DOMAIN=$OPENSHIFT_DOMAIN ./keycloak/create-tls-cert-secret.sh
```

Keycloak's public TLS certificate will be mounted from a ConfigMap into the chain of trusted certificates in the Authorino pod.

## 4. Install Authorino

### Install the Authorino Operator ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$curl%20-sSl%20https://raw.githubusercontent.com/Kuadrant/authorino-operator/volumes/config/deploy/manifests.yaml%20%7C%20sed%20's/quay.io%5C/3scale%5C/authorino-operator:v0.0.1/quay.io%5C/guicassolato%5C/authorino:operator-pr20/g'%20%7C%20kubectl%20apply%20-f%20-))

```sh
curl -sSl https://raw.githubusercontent.com/Kuadrant/authorino-operator/volumes/config/deploy/manifests.yaml | sed 's/quay.io\/3scale\/authorino-operator:v0.0.1/quay.io\/guicassolato\/authorino:operator-pr20/g' | kubectl apply -f -
```

### Deploy Authorino ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$kubectl%20-n%20apicurio-registry%20apply%20-f%20authorino.yaml))

```sh
kubectl -n apicurio-registry apply -f authorino.yaml
```

## 5. Install Limitador

#### Install the Limitador Operator ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$./limitador.sh))

```sh
./limitador.sh
```

#### Deploy Limitador ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$kubectl%20-n%20apicurio-registry%20apply%20-f%20limitador.yaml))
```sh
kubectl -n apicurio-registry apply -f limitador.yaml
```

## 6. Deploy Envoy ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$sed%20%22s/%5C$%7BOPENSHIFT_DOMAIN%7D/$OPENSHIFT_DOMAIN/g%22%20envoy.yaml%20%7C%20kubectl%20-n%20apicurio-registry%20apply%20-f%20-))

```sh
sed "s/\${OPENSHIFT_DOMAIN}/$OPENSHIFT_DOMAIN/g" envoy.yaml | kubectl -n apicurio-registry apply -f -
```

### Try Apicurio Registry protected with Envoy and Authorino ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$firefox%20--private-window%20https://apicurio-registry.apps.$OPENSHIFT_DOMAIN))

```sh
firefox --private-window https://apicurio-registry.apps.$OPENSHIFT_DOMAIN
```

Authenticate in Keycloak with any of the user credentials provided:

- **Admin user**<br/>
    Username: registry-admin [❏](didact://?commandId=vscode.didact.copyToClipboardCommand&text=registry-admin)<br/>
    Password: changeme [❏](didact://?commandId=vscode.didact.copyToClipboardCommand&text=changeme)<br/>
- **API developer**<br/>
    Username: registry-developer [❏](didact://?commandId=vscode.didact.copyToClipboardCommand&text=registry-developer)<br/>
    Password: changeme [❏](didact://?commandId=vscode.didact.copyToClipboardCommand&text=changeme)<br/>
- **API user**<br/>
    Username: registry-user [❏](didact://?commandId=vscode.didact.copyToClipboardCommand&text=registry-user)<br/>
    Password: changeme [❏](didact://?commandId=vscode.didact.copyToClipboardCommand&text=changeme)<br/>

## 7. Add access control and rate-limit to the Apicurio Registry API

### Create the `AuthConfig` ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$sed%20%22s/%5C$%7BOPENSHIFT_DOMAIN%7D/$OPENSHIFT_DOMAIN/g%22%20authconfig.yaml%20%7C%20kubectl%20-n%20apicurio-registry%20apply%20-f%20-))

```sh
sed "s/\${OPENSHIFT_DOMAIN}/$OPENSHIFT_DOMAIN/g" authconfig.yaml | kubectl -n apicurio-registry apply -f -
```

### Create the `RateLimit` ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$kubectl%20-n%20apicurio-registry%20apply%20-f%20ratelimit.yaml))

```sh
kubectl -n apicurio-registry apply -f ratelimit.yaml
```

### Try Apicurio Registry with access control and rate limits

#### Authorization

Authorino will apply the same R/W permissions otherwise enforced by Apicurio Registry's built-in authorization based on the user roles:

| API    | Method | Path                                                              | Permission | Owner |
| ------ | ------ | ----------------------------------------------------------------- |:----------:|:-----:|
| Groups | GET    | /apis/registry/v2/groups/{gid}/artifacts                          | Read       |       |
| Groups | POST   | /apis/registry/v2/groups/{gid}/artifacts                          | Write      |       |
| Groups | DELETE | /apis/registry/v2/groups/{gid}/artifacts                          | Write      |       |
| Groups | GET    | /apis/registry/v2/groups/{gid}/artifacts/{aid}                    | Read       | Y     |
| Groups | PUT    | /apis/registry/v2/groups/{gid}/artifacts/{aid}                    | Write      | Y     |
| Groups | DELETE | /apis/registry/v2/groups/{gid}/artifacts/{aid}                    | Write      | Y     |
| Groups | PUT    | /apis/registry/v2/groups/{gid}/artifacts/{aid}/state              | Write      | Y     |
| Groups | GET    | /apis/registry/v2/groups/{gid}/artifacts/{aid}/meta               | Read       | Y     |
| Groups | PUT    | /apis/registry/v2/groups/{gid}/artifacts/{aid}/meta               | Write      | Y     |
| Groups | POST   | /apis/registry/v2/groups/{gid}/artifacts/{aid}/meta               | Read       | Y     |
| Groups | GET    | /apis/registry/v2/groups/{gid}/artifacts/{aid}/versions           | Read       | Y     |
| Groups | POST   | /apis/registry/v2/groups/{gid}/artifacts/{aid}/versions           | Write      | Y     |
| Groups | GET    | /apis/registry/v2/groups/{gid}/artifacts/{aid}/versions/vid       | Read       | Y     |
| Groups | PUT    | /apis/registry/v2/groups/{gid}/artifacts/{aid}/versions/vid/state | Write      | Y     |
| Groups | GET    | /apis/registry/v2/groups/{gid}/artifacts/{aid}/versions/vid/meta  | Read       | Y     |
| Groups | PUT    | /apis/registry/v2/groups/{gid}/artifacts/{aid}/versions/vid/meta  | Write      | Y     |
| Groups | DELETE | /apis/registry/v2/groups/{gid}/artifacts/{aid}/versions/vid/meta  | Write      | Y     |
| Groups | GET    | /apis/registry/v2/groups/{gid}/artifacts/{aid}/rules              | Read       | Y     |
| Groups | POST   | /apis/registry/v2/groups/{gid}/artifacts/{aid}/rules              | Write      | Y     |
| Groups | DELETE | /apis/registry/v2/groups/{gid}/artifacts/{aid}/rules              | Write      | Y     |
| Groups | GET    | /apis/registry/v2/groups/{gid}/artifacts/{aid}/rules/{rid}        | Read       | Y     |
| Groups | PUT    | /apis/registry/v2/groups/{gid}/artifacts/{aid}/rules/{rid}        | Write      | Y     |
| Groups | DELETE | /apis/registry/v2/groups/{gid}/artifacts/{aid}/rules/{rid}        | Write      | Y     |
| Groups | PUT    | /apis/registry/v2/groups/{gid}/artifacts/{aid}/test               | Read       | Y     |
| IDs    | GET    | /apis/registry/v2/ids/contentIds/{cid}                            | Read       |       |
| IDs    | GET    | /apis/registry/v2/ids/globalIds/{gid}                             | Read       |       |
| IDs    | GET    | /apis/registry/v2/ids/contentHashes/{hash}                        | Read       |       |
| Search | GET    | /apis/registry/v2/search/artifacts                                | Read       |       |
| Search | POST   | /apis/registry/v2/search/artifacts                                | Read       |       |
| Admin  | GET    | /apis/registry/v2/admin/rules                                     | Admin      |       |
| Admin  | POST   | /apis/registry/v2/admin/rules                                     | Admin      |       |
| Admin  | GET    | /apis/registry/v2/admin/rules/{rid}                               | Admin      |       |
| Admin  | PUT    | /apis/registry/v2/admin/rules/{rid}                               | Admin      |       |
| Admin  | DELETE | /apis/registry/v2/admin/rules/{rid}                               | Admin      |       |
| Admin  | DELETE | /apis/registry/v2/admin/rules                                     | Admin      |       |
| Admin  | GET    | /apis/registry/v2/admin/loggers                                   | Admin      |       |
| Admin  | GET    | /apis/registry/v2/admin/loggers/{lid}                             | Admin      |       |
| Admin  | PUT    | /apis/registry/v2/admin/loggers/{lid}                             | Admin      |       |
| Admin  | DELETE | /apis/registry/v2/admin/loggers/{lid}                             | Admin      |       |
| Admin  | GET    | /apis/registry/v2/admin/export                                    | Admin      |       |
| Admin  | POST   | /apis/registry/v2/admin/export                                    | Admin      |       |
| Admin  | GET    | /apis/registry/v2/admin/roleMappings                              | Admin      |       |
| Admin  | POST   | /apis/registry/v2/admin/roleMappings                              | Admin      |       |
| Admin  | GET    | /apis/registry/v2/admin/roleMappings/{pid}                        | Admin      |       |
| Admin  | PUT    | /apis/registry/v2/admin/roleMappings/{pid}                        | Admin      |       |
| Admin  | DELETE | /apis/registry/v2/admin/roleMappings/{pid}                        | Admin      |       |
| System | GET    | /apis/registry/v2/system/info                                     | None       |       |
| Users  | GET    | /apis/registry/v2/users/me                                        | None       |       |

For the endpoints where an artifact ID is in the path, Authorino will try to match the artifact's `createdBy` property (fetched from the Apicurio Registry artifact metadata API directly endpoint) to the value of `preferred_username` claim of the JWT. In cases where Apicurio Registry returns an empty or null `createdBy`, this authorization rule will be skipped.

#### Rate-limits

For this demo, only POST requests to `/apis/registry/v2/groups/default/artifacts` are rate-limited. No more than 1 artifact can be created every 60 seconds across all users.

## Signing out

### Close the session in Keycloak

To sign out, close the session in Keycloak Account Management: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$firefox%20--private-window%20https://keycloak-apicurio-registry.apps.$OPENSHIFT_DOMAIN/auth/realms/apicurio-registry/account))

```sh
firefox --private-window https://keycloak-apicurio-registry.apps.$OPENSHIFT_DOMAIN/auth/realms/apicurio-registry/account
```

(Click on the _Sign out_ button on the top.)

...or by navigating to the logout endpoint: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$firefox%20--private-window%20https://keycloak-apicurio-registry.apps.$OPENSHIFT_DOMAIN/auth/realms/apicurio-registry/protocol/openid-connect/logout))

```sh
firefox --private-window https://keycloak-apicurio-registry.apps.$OPENSHIFT_DOMAIN/auth/realms/apicurio-registry/protocol/openid-connect/logout
```

### Clear the session cookies in Envoy

Use the Envoy-provided endpoint to clear the authentication cookies: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$firefox%20--private-window%20https://apicurio-registry.apps.$OPENSHIFT_DOMAIN/signout))

```sh
firefox --private-window https://apicurio-registry.apps.$OPENSHIFT_DOMAIN/signout
```

## Cleanup

Remove Apicurio Registry from the scope of Authorino: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$kubectl%20-n%20apicurio-registry%20delete%20-f%20authconfig.yaml))

```sh
kubectl -n apicurio-registry delete -f authconfig.yaml
```

Remove the rate-limits definition: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$kubectl%20-n%20apicurio-registry%20delete%20-f%20ratelimit.yaml))

```sh
kubectl -n apicurio-registry delete -f ratelimit.yaml
```

Decommision Envoy: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$kubectl%20-n%20apicurio-registry%20delete%20-f%20envoy.yaml))

```sh
kubectl -n apicurio-registry delete -f envoy.yaml
```

Decommission Authorino: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$kubectl%20-n%20apicurio-registry%20delete%20-f%20authorino.yaml))

```sh
kubectl -n apicurio-registry delete -f authorino.yaml
```

Decommission Limitador: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$kubectl%20-n%20apicurio-registry%20delete%20-f%20limitador.yaml))

```sh
kubectl -n apicurio-registry delete -f limitador.yaml
```

Uninstall Authorino Operator and the Authorino CRDs: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$kubectl%20delete%20-f%20https://raw.githubusercontent.com/Kuadrant/authorino-operator/volumes/config/deploy/manifests.yaml))

```sh
kubectl delete -f https://raw.githubusercontent.com/Kuadrant/authorino-operator/volumes/config/deploy/manifests.yaml
```

Uninstall Limitador Operator and the Limitador CRDs: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$./limitador.sh%20cleanup))

```sh
./limitador.sh cleanup
```

Uninstall Keycloak and the Keycloak CRDs: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$./keycloak/uninstall.sh))

```sh
./keycloak/uninstall.sh
```

Decommission Apicurio Registry: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$kubectl%20-n%20apicurio-registry%20delete%20-f%20apicurio-registry.yaml))

```sh
kubectl -n apicurio-registry delete -f apicurio-registry.yaml
```

Delete the Apicurio Registry database: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$kubectl%20-n%20apicurio-registry%20delete%20-f%20apicurio-registry-database.yaml))

```sh
kubectl -n apicurio-registry delete -f apicurio-registry-database.yaml
```

Delete the namespace: ([▶︎](didact://?commandId=vscode.didact.sendNamedTerminalAString&text=demo$$kubectl%20delete%20namespace%20apicurio-registry))

```sh
kubectl delete namespace apicurio-registry
```
