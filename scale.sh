#!/bin/bash
scale=2
deploys=(balancereader contacts frontend ledgerwriter transactionhistory userservice)
for deploy in "${deploys[@]}"
do
	kubectl scale --replicas=$scale deploy/$deploy -n bank-of-anthos
done