#!/usr/bin/env bash

## Source variables
VERSION_GARDENER=3.9.0
export VERSION_GARDENER
export cloud_provider
export gardener_version
source variables.tf
GARDENER_PASSWORD=$(/bin/cat /dev/urandom | /usr/bin/strings -e s -n 1 | /usr/bin/tr -d -c 'abcdef0123456789' | /bin/dd bs=1 count=16 status=none)
export GARDENER_PASSWORD
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


## Template acre.yaml
cp acre.yaml.tmpl acre.yaml
yq eval '.credentials.username = env(USER_NAME)' -i acre.yaml
yq eval '.credentials.password = env(PASSWORD)' -i acre.yaml
yq eval '.credentials.tenantName = env(TENANT_NAME)' -i acre.yaml
yq eval '.credentials.domainName = env(DOMAIN_NAME)' -i acre.yaml
yq eval '.credentials.userDomainName = env(DOMAIN_NAME)' -i acre.yaml
yq eval '.credentials.authURL = env(KEYSTONE_AUTH_URL)' -i acre.yaml
yq eval '.credentials.OS_AUTH_URL = env(KEYSTONE_AUTH_URL)' -i acre.yaml
yq eval '.credentials.region = env(REGION)' -i acre.yaml
yq eval '.landscape.name = env(cloud_provider)' -i acre.yaml
yq eval '.landscape.domain = env(dns_domain)' -i acre.yaml
yq eval '.landscape.cert-manager.email = env(letsencrypt_mail)' -i acre.yaml
yq eval '.landscape.cert-manager.server.url = env(letsencrypt_live)' -i acre.yaml
yq eval '.landscape.cluster.domain = env(dns_domain)' -i acre.yaml
yq eval '.landscape.iaas.[0].seedConfig.backup.active = env(backup_enabled)' -i acre.yaml
yq eval '.landscape.iaas.[0].region = env(REGION)' -i acre.yaml
yq eval '.landscape.iaas.[0].zones[0] = env(availability_zone)' -i acre.yaml
yq eval '.landscape.iaas.[0].floatingPools[0].name = env(public)' -i acre.yaml
yq eval '.landscape.iaas.[0].machineTypes[0].name = env(flavor_worker)' -i acre.yaml
yq eval '.landscape.iaas.[0].machineTypes[0].cpu = env(flavor_worker_cpu)' -i acre.yaml
yq eval '.landscape.iaas.[0].machineTypes[0].memory = env(flavor_worker_memory)' -i acre.yaml
yq eval '.landscape.iaas.[0].machineTypes[0].storage.size = env(flavor_worker_disk)' -i acre.yaml
yq eval '.landscape.iaas.[0].machineImageDefinitions[0].versions[0].image = env(image)' -i acre.yaml
yq eval '.landscape.etcd.backup.active = env(backup_enabled)' -i acre.yaml
yq eval '.landscape.identity.users[0].email = "admin@" + env(dns_domain)' -i acre.yaml
yq eval '.landscape.identity.users[0].password = env(GARDENER_PASSWORD)' -i acre.yaml

# clone garden-setup
mkdir landscape
git clone https://github.com/gardener/garden-setup --branch ${VERSION_GARDENER} landscape/crop
cp "$HOME"/workload-cluster.yaml landscape/kubeconfig
cp acre.yaml landscape/


# Install vpa
git clone https://github.com/kubernetes/autoscaler
pushd autoscaler/vertical-pod-autoscaler || exit
export KUBECONFIG=$HOME/workload-cluster.yaml
bash hack/vpa-up.sh
popd || exit


# install sow
# https://github.com/gardener/garden-setup
git clone https://github.com/gardener/sow

# Deploy
pushd landscape || exit
../sow/docker/bin/sow deploy -A
popd || exit
