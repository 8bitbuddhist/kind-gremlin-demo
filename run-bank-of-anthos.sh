#!/usr/bin/env bash
kubectl delete ns bank-of-anthos
kubectl create ns bank-of-anthos
kubectl apply -f bank-of-anthos/extras/jwt/jwt-secret.yaml -n bank-of-anthos
kubectl apply -f bank-of-anthos/kubernetes-manifests/ -n bank-of-anthos

# Increase user session timeout to one year
kubectl set env deployment/userservice TOKEN_EXPIRY_SECONDS=31536000 -n bank-of-anthos

# Deploy ingress controller
kubectl apply -f bank-of-anthos-ingress.yaml -n bank-of-anthos

# Scale deployments and add annotations so they appear in Gremlin automagically.
# Also modify attributes so deploys don't crash due to missing metrics.
scale=2
if ! [ -z "$1" ]; then
	scale=$1
fi

# Disable metrics and tracing on all containers to prevent crashes
kubectl set env pod --all ENABLE_METRICS=false -n bank-of-anthos
kubectl set env pod --all ENABLE_TRACING=false -n bank-of-anthos

echo "Scaling to $scale replicas"

deploys=(balancereader contacts frontend ledgerwriter transactionhistory userservice)
for deploy in "${deploys[@]}"
do
#	kubectl patch deploy/$deploy --patch '{"spec": {"template": {"spec": {"containers": {"env": [{"name": "ENABLE_METRICS","value": "false"}]}}}}}'
#	kubectl patch deploy/$deploy --patch '{"spec": {"template": {"spec": {"containers": {"env": [{"name": "ENABLE_TRACING","value": "false"}]}}}}}'

	kubectl annotate --overwrite deploy/$deploy gremlin.com/service-id=$deploy -n bank-of-anthos
	kubectl scale --replicas=$scale deploy/$deploy -n bank-of-anthos
done

# Update StatefulSets
kubectl annotate --overwrite statefulset/accounts-db gremlin.com/service-id="accounts-db" -n bank-of-anthos
kubectl annotate --overwrite statefulset/ledger-db gremlin.com/service-id="ledger-db" -n bank-of-anthos
