#!/usr/bin/env bash
# Optionally scales deployments, and adds annotations so they appear in Gremlin automagically
scale=2
if ! [ -z "$1" ]; then
	scale=$1
fi

# Disable metrics and tracing on all containers to prevent crashes
kubectl set env rc --all ENABLE_METRICS=false -n bank-of-anthos
kubectl set env rc --all ENABLE_TRACING=false -n bank-of-anthos

echo "Scaling to $scale replicas"

deploys=(balancereader contacts frontend ledgerwriter transactionhistory userservice)
for deploy in "${deploys[@]}"
do
#	kubectl patch deploy/$deploy -n bank-of-anthos --patch '{"spec": {"template": {"spec": {"containers": {"env": [{"name": "ENABLE_METRICS","value": "false"}]}}}}}'
#	kubectl patch deploy/$deploy -n bank-of-anthos --patch '{"spec": {"template": {"spec": {"containers": {"env": [{"name": "ENABLE_TRACING","value": "false"}]}}}}}'

	kubectl annotate --overwrite deploy/$deploy gremlin.com/service-id=$deploy -n bank-of-anthos
	kubectl scale --replicas=2 deploy/$deploy -n bank-of-anthos
done

# Update StatefulSets
kubectl annotate --overwrite statefulset/accounts-db gremlin.com/service-id="accounts-db" -n bank-of-anthos
kubectl annotate --overwrite statefulset/ledger-db gremlin.com/service-id="ledger-db" -n bank-of-anthos
