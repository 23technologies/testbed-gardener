#!/usr/bin/env bash

# versions

VERSION_GARDENCTL=0.24.1
VERSION_K9S=0.22.1
VERSION_RKE=1.2.3


chmod 0600 "$HOME/.ssh/id_rsa"

sudo apt-get install -y git
sudo snap install kubectl --classic

bash node_readyness.sh

sudo /usr/bin/wget -O /usr/local/bin/rke "https://github.com/rancher/rke/releases/download/v$VERSION_RKE/rke_linux-amd64"
sudo chmod +x /usr/local/bin/rke
rke up
mkdir -p "$HOME/.kube"
chmod 0750 "$HOME/.kube"
mv kube_config_cluster.yml .kube/config

# https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler
git clone https://github.com/kubernetes/autoscaler
pushd autoscaler/vertical-pod-autoscaler || exit
bash hack/vpa-up.sh
popd || exit

# enable kubectl completion
kubectl completion bash | sed 's/kubectl/k/gi' >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc

# install gardenctl

sudo curl -L -o /usr/local/bin/gardenctl https://github.com/gardener/gardenctl/releases/download/v"$VERSION_GARDENCTL"/gardenctl-linux-amd64
sudo chmod +x /usr/local/bin/gardenctl

# install k9s

curl -L https://github.com/derailed/k9s/releases/download/v"$VERSION_K9S"/k9s_Linux_x86_64.tar.gz | sudo tar xzf - -C /usr/local/bin/
sudo chmod +x /usr/local/bin/k9s

# install sow
# https://github.com/gardener/garden-setup

git clone https://github.com/gardener/sow
echo "export PATH=$PATH:$HOME/sow/docker/bin" >> ~/.bashrc

# apply openstack-cloud-controller
kubectl apply -f ~/openstack.yaml

# apply cinder-csi
kubectl apply -f ~/cinder.yaml

# create cloud.conf secret
kubectl create secret generic cloud-config --from-file="$HOME"/cloud.conf -n kube-system

# install yq for keycloak integration
sudo snap install yq

bash deploy.sh
bash patch_dashboard.sh
bash install_keycloak.sh
bash create_shoot.sh
bash install_demo_app.sh
sudo shutdown -r
