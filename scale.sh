#!/usr/bin/env bash
# Scales deployments and adds annotations so they appear in Gremlin automagically
scale=2
if ! [ -z "$1" ]; then
	scale=$1
fi

echo "Scaling to $scale replicas"

deploys=(balancereader contacts frontend ledgerwriter transactionhistory userservice)
for deploy in "${deploys[@]}"
do
	# Annotate for auto-discovery in Gremlin
	kubectl annotate --overwrite deploy/$deploy gremlin.com/service-id=$deploy -n bank-of-anthos

	# Scale up
	kubectl scale --replicas=$scale deploy/$deploy -n bank-of-anthos
done

# Annotate StatefulSets
kubectl annotate --overwrite statefulset/accounts-db gremlin.com/service-id="accounts-db" -n bank-of-anthos
kubectl annotate --overwrite statefulset/ledger-db gremlin.com/service-id="ledger-db" -n bank-of-anthos
