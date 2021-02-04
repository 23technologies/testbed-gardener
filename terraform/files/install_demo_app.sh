#!/usr/bin/env bash
git clone https://github.com/GoogleCloudPlatform/microservices-demo.git
while [ ! "$(kubectl --kubeconfig gardener-kubeconfig.yaml get shoot demo-shoot -n garden -o jsonpath="{.status.lastOperation.state}")" == "Succeeded" ]
do
	echo waiting for Shoot...
	sleep 20
done
kubectl --kubeconfig gardener-kubeconfig.yaml get secret -n garden demo-shoot.kubeconfig -o go-template='{{.data.kubeconfig|base64decode}}' > shoot-kubeconfig.yaml
kubectl --kubeconfig shoot-kubeconfig.yaml apply -f microservices-demo/release/kubernetes-manifests.yaml

