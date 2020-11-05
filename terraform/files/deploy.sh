#!/usr/bin/env bash

VERSION_GARDENER=3.0.0

# https://github.com/gardener/garden-setup

git clone https://github.com/gardener/sow
export PATH=$PATH:$HOME/sow/docker/bin

mkdir landscape
git clone https://github.com/gardener/garden-setup --branch ${VERSION_GARDENER} landscape/crop
cp $HOME/.kube/config landscape/kubeconfig
cat $HOME/credentials.yaml > landscape/acre.yaml
cat $HOME/acre.yaml >> landscape/acre.yaml

pushd landscape
sow order -A
sow deploy -A
popd
