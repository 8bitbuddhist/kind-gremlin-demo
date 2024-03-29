#!/bin/bash
NO_CLUSTER=0
NO_GREMLIN=0
NO_APP=0
APP_VERSION=v0.3.5	# Online Boutique version number
USE_SKAFFOLD=0
USE_STAGING=0		# Deploy to Gremlin staging instead of prod

function usage() {
	echo "Usage: run.sh [ --no-cluster ] [ --no-gremlin ] [--no-app] [--skaffold] [--staging] [cluster-name]"
	echo "Options:"
	echo "	-h | --help	Show this help screen."
	echo "	--no-app	Don't deploy the Online Boutique demo application."
	echo "  --no-cluster	Don't rebuild the Kind cluster."
	echo "	--no-gremlin	Don't deploy Gremlin."
	echo "  --skaffold		Use Skaffold to deploy Online Boutique instead of 'kubectl apply'"
	echo "  --staging			Deploy to Gremlin Staging instead of Gremlin Prod"
	echo "  cluster-name	The name of the cluster to create."
	exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
	  --no-cluster)
		  NO_CLUSTER=1
			shift
			;;
		--no-gremlin)
			NO_GREMLIN=1
			shift
			;;
		--no-app)
			NO_APP=1
			shift
			;;
	  --skaffold)
		  USE_SKAFFOLD=1
			shift
			;;
		--staging)
			USE_STAGING=1
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

# Make sure kind and kubectl are installed
if ! command -v kind &> /dev/null; then
	echo "Kind not installed. See https://kind.sigs.k8s.io/."
	exit
fi

if ! command -v kubectl &> /dev/null; then
	echo "kubectl not installed. See https://kubernetes.io/docs/tasks/tools/."
	exit
fi

if [ $NO_CLUSTER -eq 0 ]; then
	# Create the kind cluster
	kind delete cluster --name ${CLUSTER_NAME}
	kind create cluster --name ${CLUSTER_NAME} --config config.yaml
fi

if [ $NO_GREMLIN -eq 0 ]; then
	# Detect Gremlin certificate files
	GREMLIN_CERT_FILE=$(ls -1 ${GREMLIN_CERT_PATH}/*cert.pem | head -n 1)
	GREMLIN_KEY_FILE=$(ls -1 ${GREMLIN_CERT_PATH}/*key.pem | head -n 1)

	if [ -z "$GREMLIN_CERT_FILE" ] || [ -z "$GREMLIN_KEY_FILE" ]; then
		echo "Could not find Gremlin credentials. Skipping Gremlin setup."
	else
		# Create a Gremlin namespace and secret
		kubectl delete ns gremlin
		kubectl create ns gremlin
		kubectl create secret generic -n gremlin gremlin-team-cert \
			--from-file=gremlin.cert=${GREMLIN_CERT_FILE} \
			--from-file=gremlin.key=${GREMLIN_KEY_FILE} \
			--from-literal=GREMLIN_TEAM_ID=${GREMLIN_TEAM_ID} \
			--from-literal=GREMLIN_CLUSTER_ID=${CLUSTER_NAME}

		# Deploy Gremlin
		helm repo add gremlin https://helm.gremlin.com

		if [ $USE_STAGING -eq 0 ]; then
		helm install gremlin gremlin/gremlin \
			--namespace gremlin \
			--set gremlin.secret.name=gremlin-team-cert \
			--set gremlin.hostNetwork=true \
			--set gremlin.hostPID=true \
			--set gremlin.collect.processes=true \
			--set gremlin.apparmor=unconfined \
			--set gremlin.container.driver=containerd-runc \
			--set gremlin.client.tags="cluster=${CLUSTER_NAME}"
		else
			helm install gremlin gremlin/gremlin \
				--namespace gremlin \
				--set gremlin.secret.name=gremlin-team-cert \
				--set gremlin.hostPID=true \
				--set gremlin.collect.processes=true \
				--set gremlin.apparmor=unconfined \
				--set gremlin.container.driver=containerd-runc \
				--set gremlin.client.tags="cluster=${CLUSTER_NAME}" \
				--set gremlin.serviceUrl=https://api.staging.gremlin.com/v1
		fi

		# AppArmor workaround (shouldn't be necesary, but just in case)
		kubectl patch daemonset -n gremlin gremlin -p "{
		\"spec\":{
			\"template\":{
				\"metadata\":{
					\"annotations\":{
						\"container.apparmor.security.beta.kubernetes.io/gremlin\":\"unconfined\"}}}}}"
	fi
fi

# Deploy an Nginx Ingress controller and wait for it to rollout
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx

# Deploy the demo application
if [ $NO_APP -eq 0 ]; then
	kubectl create ns gremlin-boutique
	if [ $USE_SKAFFOLD -eq 1 ]; then
		cd gremlin-boutique
		skaffold run --namespace gremlin-boutique
		cd ..
	else
		kubectl apply -f gremlin-boutique/release/kubernetes-manifests.yaml -n gremlin-boutique
	fi
	kubectl apply -f gremlin-boutique-ingress.yaml -n gremlin-boutique
fi

# Print and save config
sudo kubectl config view --raw > kubeconfig
echo "kubectl config saved to \"kubeconfig\"."
