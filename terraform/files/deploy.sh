#!/usr/bin/env bash

VERSION_GARDENER=3.0.0

mkdir landscape
git clone https://github.com/gardener/garden-setup --branch ${VERSION_GARDENER} landscape/crop
cp $HOME/.kube/config landscape/kubeconfig
cp $HOME/acre.yaml landscape/

pushd landscape
sow order -A
sow deploy -A
popd
