#!/bin/bash
NO_GREMLIN=0
NO_APP=0

function usage() {
	echo "Usage: run.sh [ --no-gremlin ] [--no-app] [cluster-name]"
	echo "Options:"
	echo "	-h | --help	Show this help screen."
	echo "	--no-app 	Don't deploy the Online Boutique demo application."
	echo "	--no-gremlin	Don't deploy Gremlin."
	echo "  cluster-name	The name of the cluster to create."
	exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
		--no-gremlin)
			NO_GREMLIN=1
			shift
			;;
		--no-app)
			NO_APP=1
			shift
			;;
		--help|-h)
			usage
			shift
			;;
		*)
			break
			;;
	esac
done

source .env

if ! [ -z "$1"]; then
	# Overwrite CLUSTER_NAME set in .env
	CLUSTER_NAME=$1
fi

if [ -z "$CLUSTER_NAME" ]; then
	echo "Cluster name required."
	usage
	exit
fi

# Create the kind cluster
kind delete cluster --name ${CLUSTER_NAME}
kind create cluster --name ${CLUSTER_NAME} --config config.yaml

if [ $NO_GREMLIN -eq 0 ]; then
	# Detect Gremlin certificate files
	GREMLIN_CERT_FILE=$(ls -1 ${GREMLIN_CERT_PATH}/*cert.pem | head -n 1)
	GREMLIN_KEY_FILE=$(ls -1 ${GREMLIN_CERT_PATH}/*key.pem | head -n 1)

	# Create a Gremlin namespace and secret
	kubectl create ns gremlin
	kubectl create secret generic -n gremlin gremlin-team-cert \
		--from-file=gremlin.cert=${GREMLIN_CERT_FILE} \
		--from-file=gremlin.key=${GREMLIN_KEY_FILE} \
		--from-literal=GREMLIN_TEAM_ID=${GREMLIN_TEAM_ID} \
		--from-literal=GREMLIN_CLUSTER_ID=${GREMLIN_CLUSTER_ID}

	# Deploy Gremlin
	helm repo add gremlin https://helm.gremlin.com
	helm install gremlin gremlin/gremlin \
		--namespace gremlin \
		--set gremlin.secret.name=gremlin-team-cert \
		--set gremlin.hostPID=true \
		--set gremlin.container.driver=containerd-runc \
		--set gremlin.client.tags="cluster=${CLUSTER_NAME}"
fi

# Deploy an Nginx Ingress controller and wait for it to rollout
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx

# Deploy the demo application
if [ $NO_APP -eq 0 ]; then
	kubectl create ns microservices-demo
	kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml -n microservices-demo
	kubectl apply -f microservices-demo-ingress.yaml -n microservices-demo
fi