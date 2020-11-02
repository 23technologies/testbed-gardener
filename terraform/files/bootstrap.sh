#!/usr/bin/env bash

# versions

VERSION_DASHBOARD=2.0.4
VERSION_GARDENCTL=0.23.0
VERSION_K9S=0.22.1

# prepare network

ping -c 1 gardener-primary
ping -c 1 gardener-worker-0
ping -c 1 gardener-worker-1
ping -c 1 gardener-worker-2
ping -c 1 gardener-worker-3

sudo apt-get install -y git

sudo snap install kubectl --classic
sudo snap install docker

cat <<EOT | sudo tee /var/snap/docker/current/config/daemon.json
{
    "log-level":        "error",
    "mtu":              1400,
    "storage-driver":   "overlay2"
}
EOT
sudo snap restart docker

chmod 0600 $HOME/.ssh/id_rsa
mkdir -p $HOME/.kube
chmod 0750 $HOME/.kube
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null gardener-primary:$HOME/k3s.yaml $HOME/.kube/config
sed -i 's/127.0.0.1/gardener-primary/g' $HOME/.kube/config

# https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler

git clone https://github.com/kubernetes/autoscaler
pushd autoscaler/vertical-pod-autoscaler
bash hack/vpa-up.sh
popd

# install gardenctl

sudo curl -L -o /usr/local/bin/gardenctl https://github.com/gardener/gardenctl/releases/download/v$VERSION_GARDENCTL/gardenctl-linux-amd64
sudo chmod +x /usr/local/bin/gardenctl

# install k9s

curl -L https://github.com/derailed/k9s/releases/download/v$VERSION_K9S/k9s_Linux_x86_64.tar.gz | sudo tar xzf - -C /usr/local/bin/
sudo chmod +x /usr/local/bin/k9s
