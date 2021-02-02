#!/usr/bin/env bash
kubectl get secrets  -n garden garden-kubeconfig-for-admin -o go-template='{{.data.kubeconfig|base64decode}}' > gardener-kubeconfig.yaml
kubectl --kubeconfig gardener-kubeconfig.yaml apply -f demo-shoot.yaml
