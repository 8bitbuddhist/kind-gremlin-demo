#!/usr/bin/env bash

source .env

# Detect Gremlin certificate files
GREMLIN_CERT_FILE=$(ls -1 ${GREMLIN_CERT_PATH}/*cert.pem | head -n 1)
GREMLIN_KEY_FILE=$(ls -1 ${GREMLIN_CERT_PATH}/*key.pem | head -n 1)

if [ -z "$GREMLIN_CERT_FILE" ] || [ -z "$GREMLIN_KEY_FILE" ]; then
	echo "Could not find Gremlin credentials. Gremlin setup failed."
else
	# Create a Gremlin namespace and secret
	kubectl delete ns gremlin
	kubectl create ns gremlin
	kubectl create secret generic gremlin-team-cert \
		--namespace=gremlin \
		--from-file=gremlin.cert=${GREMLIN_CERT_FILE} \
		--from-file=gremlin.key=${GREMLIN_KEY_FILE} \
		--from-literal=GREMLIN_TEAM_ID=${GREMLIN_TEAM_ID} \
		--from-literal=GREMLIN_CLUSTER_ID=${CLUSTER_NAME} \
		--from-literal=GREMLIN_CLIENT_TAGS="cluster=${CLUSTER_NAME},os-name=Debian,os-type=Linux"

	# Deploy Gremlin
	helm repo add gremlin https://helm.gremlin.com
	helm install gremlin gremlin/gremlin \
		--namespace gremlin \
		--set gremlin.secret.name=gremlin-team-cert \
		--set gremlin.hostPID=true \
		--set gremlin.collect.processes=true \
		--set gremlin.apparmor=unconfined \
		--set gremlin.container.driver=containerd-linux \
		--set gremlin.client.tags="cluster=${CLUSTER_NAME},os-name=Debian,os-type=Linux"

	# AppArmor workaround (shouldn't be necesary)
    kubectl patch daemonset -n gremlin gremlin -p "{                                                                                                  \"spec\":{                                                                                                                                            \"template\":{                                                                                                                                        \"metadata\":{                                                                                                                                        \"annotations\":{
                        \"container.apparmor.security.beta.kubernetes.io/gremlin\":\"unconfined\"}}}}}"
fi
