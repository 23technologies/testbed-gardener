#!/bin/bash
rand() {
  #cat /dev/urandom | tr -d -c 'cbdefghijklnrtuvCBDEFGHIJKLNRTUV0123456789' | dd bs=1 count=32 status=none
  tr -d -c 'cbdefghijklnrtuvCBDEFGHIJKLNRTUV0123456789' < /dev/urandom | dd bs=1 count=32 status=none
}
USER=user
PW=""
TESTUSER=test01
TESTPW=$(rand)
REALM=gardener
CLIENT=gardener
CLIENT_SECRET=""
REDIRECT_URI="https://$(kubectl get ingress -n garden gardener-dashboard-ingress -o=jsonpath='{.spec.rules[0].host}')/oidc/callback"
ISSUER=""

# Installation
sudo snap install helm --classic
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install keycloak-23t bitnami/keycloak
while [ -z "$(kubectl get svc keycloak-23t -o jsonpath="{.status.loadBalancer.ingress[0].ip}")" ]
do
	echo waiting for LoadBalancer
	sleep 20
done
PW=$(kubectl get secret --namespace default keycloak-23t -o jsonpath="{.data.admin-password}" | base64 --decode)
ISSUER="http://$(kubectl get service keycloak-23t -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/auth/realms/$REALM"
URL="https://$(kubectl get ingress -n garden gardener-dashboard-ingress -o=jsonpath='{.spec.rules[0].host}')/*"

# Wait for the rollout...
kubectl rollout status statefulset keycloak-23t

# Configuration of Keycloak
# Create realm
echo "----"
echo "Create realm:"
kubectl exec -ti keycloak-23t-0 -- /opt/bitnami/keycloak/bin/kcadm.sh create realms -s realm=$REALM -s enabled=true -s sslRequired=NONE -s displayName='Gardener' --server http://localhost:8080/auth --user "$USER" --password "$PW" --realm master
# Create client
echo "----"
echo "Create client:"
kubectl exec -ti keycloak-23t-0 -- /opt/bitnami/keycloak/bin/kcadm.sh create clients -r $REALM -s clientId=$CLIENT -s clientAuthenticatorType=client-secret -s implicitFlowEnabled=true -s "redirectUris=[\"$URL\"]" --server http://localhost:8080/auth --user $USER --password "$PW" --realm master
# Get client ID
echo "----"
echo "Get client ID:"
ID=$(kubectl exec -ti keycloak-23t-0 -- /opt/bitnami/keycloak/bin/kcadm.sh get clients -q clientId="$CLIENT" --fields id --format csv -r "$REALM" --server http://localhost:8080/auth --user "$USER" --password "$PW" --realm master | grep -v Logging|sed 's/\"//g' |sed 's/\n//'| sed 's/\r//')
echo "Client ID: $ID"
# Get Client Secret
echo "----"
echo "Get Client Secret:"
CLIENT_SECRET=$(kubectl exec -ti keycloak-23t-0 -- /opt/bitnami/keycloak/bin/kcadm.sh get clients/"$ID"/client-secret --fields value --format csv -r "$REALM" --server http://localhost:8080/auth --user "$USER" --password "$PW" --realm master | grep -v Logging | sed 's/"//g' | sed 's/\n//'|sed 's/\r//')
echo "Client Secret: $CLIENT_SECRET"
# Create user
echo "----"
echo "Create User:"
kubectl exec -ti keycloak-23t-0 -- /opt/bitnami/keycloak/bin/kcadm.sh create users -s username="$TESTUSER" -s firstName="$TESTUSER" -s emailVerified=true -s enabled=true -s email="$TESTUSER"@test.com -r "$REALM" --server http://localhost:8080/auth --user $USER --password "$PW" --realm master

# Set Password
echo "----"
echo "Set Password:"
kubectl exec -ti keycloak-23t-0 -- /opt/bitnami/keycloak/bin/kcadm.sh set-password -r $REALM --username "$TESTUSER" --new-password "$TESTPW" --server http://localhost:8080/auth --user $USER --password "$PW" --realm master

echo "Created user $TESTUSER with password $TESTPW"

# Connect dex to keycloak
# Get old config
echo "----"
echo "Get old dex config"
kubectl get configmap -n garden identity-configmap -o jsonpath='{.data.config\.yaml}' > dexconfig.yaml

# Update
echo "----"
echo "Update config with yq"
yq eval '.connectors = [{"type": "oidc", "id": "keycloak", "name": "keycloak", "config": {"issuer": "'"$ISSUER"'", "clientID": "'"$CLIENT"'", "clientSecret": "'"$CLIENT_SECRET"'", "redirectURI": "'"$REDIRECT_URI"'"}}] ' -i dexconfig.yaml
kubectl delete -n garden configmap identity-configmap
kubectl create configmap identity-configmap -n garden --from-file=config.yaml=dexconfig.yaml
kubectl delete pod -n garden -l=app=identity

