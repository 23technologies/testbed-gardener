#!/usr/bin/env bash

VERSION_GARDENER=3.9.0

mkdir landscape
git clone https://github.com/gardener/garden-setup --branch ${VERSION_GARDENER} landscape/crop
cp "$HOME"/.kube/config landscape/kubeconfig
cp "$HOME"/acre.yaml landscape/

pushd landscape || exit
# only temporaray fix as long as that component is broken
rm -rf crop/components/monitoring/gardener-metrics-exporter
#$HOME/sow/docker/bin/sow order -A
"$HOME"/sow/docker/bin/sow deploy -A
popd || exit
