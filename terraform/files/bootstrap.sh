#!/usr/bin/env bash

# versions

VERSION_DASHBOARD=2.0.4
VERSION_GARDENCTL=0.23.0

# prepare network

ping -c 1 gardener-primary.gardener.okeanos.xyz
ping -c 1 gardener-worker-0.gardener.okeanos.xyz
ping -c 1 gardener-worker-1.gardener.okeanos.xyz
ping -c 1 gardener-worker-2.gardener.okeanos.xyz
ping -c 1 gardener-worker-3.gardener.okeanos.xyz

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

# install k8s dashboard

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v${VERSION_DASHBOARD}/aio/deploy/recommended.yaml

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin
  namespace: kubernetes-dashboard
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin
  namespace: kubernetes-dashboard
EOF

# install gardenctl

sudo curl -L -o /usr/local/bin/gardenctl https://github.com/gardener/gardenctl/releases/download/v$VERSION_GARDENCTL/gardenctl-linux-amd64
sudo chmod +x /usr/local/bin/gardenctl

# install the local path provisioner

kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
