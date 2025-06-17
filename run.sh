#!/usr/bin/env bash
NO_CLUSTER=0
NO_GREMLIN=0
NO_APP=0
USE_SKAFFOLD=0
USE_STAGING=0

function usage() {
	echo "Usage: run.sh [ --no-cluster ] [ --no-gremlin ] [--no-app] [--skaffold] [--staging] [cluster-name]"
	echo "Options:"
	echo "	-h | --help	Show this help screen."
	echo "	--no-app		Don't deploy the Bank of Anthos demo application."
	echo "  --no-cluster	Don't rebuild the Kind cluster."
	echo "	--no-gremlin	Don't deploy Gremlin."
	echo "  --skaffold		Use Skaffold to deploy Bank of Anthos instead of using existing images."
	echo "  --staging		Deploy to Gremlin Staging instead of Gremlin Prod"
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

# Make sure kubectl is installed
if ! command -v kubectl &> /dev/null; then
	echo "kubectl not installed. See https://kubernetes.io/docs/tasks/tools/."
	exit
fi

# Make sure Helm is installed
if ! command -v helm &> /dev/null; then
	echo "Helm not installed. See https://helm.sh/."
	exit
fi

if [ $NO_CLUSTER -eq 0 ]; then
	# Make sure kind is installed
	if ! command -v kind &> /dev/null; then
		echo "Kind not installed. See https://kind.sigs.k8s.io/."
		exit
	fi
	
	# Create the kind cluster
	sudo kind delete cluster --name ${CLUSTER_NAME}
	sudo kind create cluster --name ${CLUSTER_NAME} --config config.yaml

	# Increase the host's file limit so we don't get "too many files" errors.
	# For details, see https://github.com/kubeflow/manifests/issues/2087#issuecomment-1101482095
	sudo sysctl fs.inotify.max_user_instances=1280
	sudo sysctl fs.inotify.max_user_watches=655360

	# Print and save config, then add
	sudo kubectl config view --raw > kubeconfig
	cp kubeconfig $HOME/.kube/kind-gremlin-demo-config
	if [[ $KUBECONFIG != *"$HOME/.kube/kind-gremlin-demo-config"* ]]; then
		$KUBECONFIG=$KUBECONFIG:$HOME/.kube/kind-gremlin-demo-config
	fi

	echo "kubectl config saved."
fi

if [ $NO_GREMLIN -eq 0 ]; then
	./run-gremlin.sh
fi

# Deploy the demo application
if [ $NO_APP -eq 0 ]; then
	./run-bank-of-anthos.sh
fi
