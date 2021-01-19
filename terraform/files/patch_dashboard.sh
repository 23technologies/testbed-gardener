#!/usr/bin/env bash
DNS=$(kubectl get svc -n kube-system kube-dns --no-headers -o=custom-columns=IP:.spec.clusterIP)
PATCH=$(cat <<END_HEREDOC
spec:
  template:
    spec:
      dnsConfig:
        nameservers:
        - $DNS
        options:
        - name: ndots
          value: "5"
        searches:
        - garden.svc.cluster.local
        - svc.cluster.local
        - cluster.local
      dnsPolicy: None
END_HEREDOC
)
echo "$PATCH"
kubectl patch deployment.apps -n garden gardener-dashboard --type=strategic --patch "$PATCH"
