#!/usr/bin/env bash

VERSION_GARDENER=3.2.0

mkdir landscape
git clone https://github.com/gardener/garden-setup --branch ${VERSION_GARDENER} landscape/crop
cp "$HOME"/.kube/config landscape/kubeconfig
cp "$HOME"/acre.yaml landscape/

pushd landscape || exit
sow order -A
sow deploy -A
popd || exit
