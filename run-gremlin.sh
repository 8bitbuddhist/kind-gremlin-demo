#!/usr/bin/env bash

source .env

# Detect Gremlin values.yaml file
if [ -z "$GREMLIN_CONFIG_FILE_PATH" ]; then
	echo "Could not find Gremlin credentials. Download the values.yaml file from Gremlin's Getting Started page and set its path in .env, then re-run this script."
else
	# Create a Gremlin namespace and secret
	kubectl delete ns gremlin
	kubectl create ns gremlin

	# Deploy Gremlin
	helm repo add gremlin https://helm.gremlin.com
	helm install gremlin gremlin/gremlin \
		--namespace gremlin \
		--values $GREMLIN_CONFIG_FILE_PATH \
		--set gremlin.container.driver=containerd-linux \
		--set gremlin.client.tags="cluster=${CLUSTER_NAME},os-name=Debian,os-type=Linux"
fi
