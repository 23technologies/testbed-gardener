#!/usr/bin/env bash

##    desc: bootstrap a cluster-api environment for openstack
## license: Apache-2.0

# version
VERSION_K9S="0.23.3"
VERSION_CLUSTERCTL="0.3.16"

# install fynns and maltes key
wget -O - https://github.com/fynluk.keys >> .ssh/authorized_keys
wget -O - https://github.com/mxmxchere.keys >> .ssh/authorized_keys

## install tools and utils at local account

# install kubectl
sudo snap install kubectl --classic

# install git
sudo apt-get install -y git

# install k9s
echo "# install k9s ${VERSION_CLUSTERCTL}"
curl -L https://github.com/derailed/k9s/releases/download/v${VERSION_K9S}/k9s_Linux_x86_64.tar.gz | tar zf - -x k9s
sudo mv ./k9s /usr/local/bin/k9s

# install clustercli
echo "# install clusterctl ${VERSION_CLUSTERCTL}"
sudo curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v${VERSION_CLUSTERCTL}/clusterctl-linux-amd64 -o /usr/local/bin/clusterctl
sudo chmod +x /usr/local/bin/clusterctl

# setup aliases and environment
echo "# setup environment"
cat <<EOF > "$HOME"/.bash_aliases
# kubernetes-cli
alias k=kubectl
source <( kubectl completion bash | sed 's# kubectl\$# k kubectl\$#' )

# clusterctl 
source <( clusterctl completion bash )

# eof
EOF

# set inputrc set tab once
cat <<EOF > .inputrc
# set tab once
set show-all-if-ambiguous on
EOF

# eof
bash install_kind.sh
bash deploy.sh

echo "Now we are going to use our new clusterctl deployed cluster..."
# https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler
git clone https://github.com/kubernetes/autoscaler
pushd autoscaler/vertical-pod-autoscaler || exit
bash hack/vpa-up.sh
popd || exit
# install sow
# https://github.com/gardener/garden-setup

git clone https://github.com/gardener/sow
echo "export PATH=$PATH:$HOME/sow/docker/bin" >> ~/.bashrc

bash sow_deploy.sh
kubectl config use-context kind-kind
kubectl scale kubeadmcontrolplanes.controlplane.cluster.x-k8s.io testcluster-control-plane --replicas=3
