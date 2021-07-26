#!/usr/bin/env bash
sudo snap install helm --classic
export cloud_provider
export gardener_version
source variables.tf
BOOTSTRAP_TOKEN_ID=$(/bin/cat /dev/urandom | /usr/bin/strings -e s -n 1 | /usr/bin/tr -d -c 'abcdef0123456789' | /bin/dd bs=1 count=6 status=none)
export BOOTSTRAP_TOKEN_ID
BOOTSTRAP_TOKEN_SECRET=$(/bin/cat /dev/urandom | /usr/bin/strings -e s -n 1 | /usr/bin/tr -d -c 'abcdef0123456789' | /bin/dd bs=1 count=16 status=none)
export BOOTSTRAP_TOKEN_SECRET
BOOTSTRAP_TOKEN
export BOOTSTRAP_TOKEN=$BOOTSTRAP_TOKEN_ID.$BOOTSTRAP_TOKEN_SECRET
KEYSTONE_AUTH_URL=$(yq eval ".clouds.$cloud_provider.auth.auth_url" ../clouds.yaml)
export KEYSTONE_AUTH_URL
REGION=$(yq eval ".clouds.$cloud_provider.region_name" ../clouds.yaml)
export REGION
DOMAIN_NAME=$(yq eval ".clouds.$cloud_provider.auth.user_domain_name" ../clouds.yaml)
export DOMAIN_NAME
PASSWORD=$(yq eval ".clouds.$cloud_provider.auth.password" ../clouds.yaml)
export PASSWORD
TENANT_NAME=$(yq eval ".clouds.$cloud_provider.auth.project_name" ../clouds.yaml)
export TENANT_NAME
USER_NAME=$(yq eval ".clouds.$cloud_provider.auth.username" ../clouds.yaml)
export USER_NAME
GARDENER_APISERVER_CA=$(yq eval ".clusters[0].cluster.certificate-authority-data" gardener-apiserver.yaml)
export GARDENER_APISERVER_CA
GARDENER_APISERVER_SERVER=$(yq eval ".clusters[0].cluster.server" gardener-apiserver.yaml)
export GARDENER_APISERVER_SERVER

# token.yaml
cp token.yaml.tmpl token.yaml
yq eval '.metadata.name = "bootstrap-token-"+env(BOOTSTRAP_TOKEN_ID)' -i token.yaml
yq eval '.stringData.token-id = env(BOOTSTRAP_TOKEN_ID)' -i token.yaml
yq eval '.stringData.token-secret = env(BOOTSTRAP_TOKEN_SECRET)' -i token.yaml
# Create token on gardener-apiserver
kubectl apply -f token.yaml --kubeconfig gardener-apiserver.yaml


# cpfl.yaml
cp cpfl.yaml.tmpl cpfl.yaml
yq eval '.metadata.name = env(cloud_provider)' -i cpfl.yaml
yq eval '.spec.machineTypes[0].cpu = env(flavor_worker_cpu)' -i cpfl.yaml
yq eval '.spec.machineTypes[0].memory = env(flavor_worker_memory)' -i cpfl.yaml
yq eval '.spec.machineTypes[0].name = env(flavor_worker)' -i cpfl.yaml
yq eval '.spec.machineTypes[0].storage.size = env(flavor_worker_disk)' -i cpfl.yaml
yq eval '.spec.providerConfig.keystoneURL = env(KEYSTONE_AUTH_URL)' -i cpfl.yaml
yq eval '.spec.providerConfig.constraints.floatingPools[0].name = env(public)' -i cpfl.yaml
yq eval '.spec.providerConfig.machineImages[0].versions[0].image = env(image)' -i cpfl.yaml
yq eval '.spec.providerConfig.machineImages[0].versions[0].regions[0].name = env(REGION)' -i cpfl.yaml
yq eval '.spec.providerConfig.machineImages[0].versions[0].regions[0].id = env(image_id)' -i cpfl.yaml
yq eval '.spec.regions[0].name = env(REGION)' -i cpfl.yaml
yq eval '.spec.regions[0].zones[0].name = env(REGION)' -i cpfl.yaml
yq eval '.spec.regions[0].zones[0].name = env(availability_zone)' -i cpfl.yaml
# Create cpfl on gardener-apiserver
kubectl apply -f cpfl.yaml --kubeconfig gardener-apiserver.yaml


# cloudsecret.yaml
cp cloudsecret.yaml.tmpl cloudsecret.yaml
yq eval '.stringData.domainName = env(DOMAIN_NAME)' -i cloudsecret.yaml
yq eval '.stringData.password = env(PASSWORD)' -i cloudsecret.yaml
yq eval '.stringData.tenantName = env(TENANT_NAME)' -i cloudsecret.yaml
yq eval '.stringData.username = env(USER_NAME)' -i cloudsecret.yaml
yq eval '.metadata.name = env(cloud_provider)+"-secret"' -i cloudsecret.yaml
yq eval '.metadata.namespace = env(gardener_project_name)' -i cloudsecret.yaml
# Create cloudsecret on gardener-apiserver
kubectl apply -f cloudsecret.yaml --kubeconfig gardener-apiserver.yaml


# secretbinding.yaml
cp secretbinding.yaml.tmpl secretbinding.yaml
yq eval '.metadata.labels."cloudprofile.garden.sapcloud.io/name" = env(cloud_provider)' -i secretbinding.yaml
yq eval '.metadata.name = env(cloud_provider) + "-secret"' -i secretbinding.yaml
yq eval '.metadata.namespace = env(gardener_project_name)' -i secretbinding.yaml
yq eval '.secretRef.name = env(cloud_provider) + "-secret"' -i secretbinding.yaml
yq eval '.secretRef.namespace = env(gardener_project_name)' -i secretbinding.yaml
# Create secretbinding on gardener-apiserver
kubectl apply -f secretbinding.yaml --kubeconfig gardener-apiserver.yaml

# bootstrap-kubeconfig.yaml
cp bootstrap-kubeconfig.yaml.tmpl bootstrap-kubeconfig.yaml
yq eval '.clusters[0].cluster.certificate-authority-data = env(GARDENER_APISERVER_CA)' -i bootstrap-kubeconfig.yaml
yq eval '.clusters[0].cluster.server = env(GARDENER_APISERVER_SERVER)' -i bootstrap-kubeconfig.yaml
yq eval '.users[0].user.token = env(BOOTSTRAP_TOKEN)' -i bootstrap-kubeconfig.yaml

# gardenlet-values.yaml
cp gardenlet-values.yaml.tmpl gardenlet-values.yaml
BOOTSTRAP_KUBECONFIG=$(cat bootstrap-kubeconfig.yaml)
export BOOTSTRAP_KUBECONFIG
yq eval '.global.gardenlet.config.gardenClientConnection.bootstrapKubeconfig.kubeconfig = env(BOOTSTRAP_KUBECONFIG)'  -i gardenlet-values.yaml
sed -i 's/^          kubeconfig:$/          kubeconfig: |/' gardenlet-values.yaml
yq eval '.global.gardenlet.config.seedConfig.metadata.name = env(cloud_provider)'  -i gardenlet-values.yaml
yq eval '.global.gardenlet.config.seedConfig.spec.dns.ingressDomain = "ing." + env(dns_domain)'  -i gardenlet-values.yaml
yq eval '.global.gardenlet.config.seedConfig.spec.provider.region = env(REGION)'  -i gardenlet-values.yaml
yq eval '.global.gardenlet.image.tag = env(gardener_version)'  -i gardenlet-values.yaml
git clone https://github.com/gardener/gardener
cd gardener || exit
git checkout "$gardener_version"
cd ..
kubectl create namespace garden --kubeconfig ../workload-cluster.yaml
helm install gardenlet gardener/charts/gardener/gardenlet --namespace garden -f gardenlet-values.yaml --wait --kubeconfig ../workload-cluster.yaml

git clone https://github.com/kubernetes/autoscaler.git
./autoscaler/vertical-pod-autoscaler/hack/vpa-up.sh
