#!/bin/bash
source .env

# Create the kind cluster
kind delete cluster --name ${KIND_CLUSTER_NAME}
kind create cluster --name ${KIND_CLUSTER_NAME} --config config.yaml

# Detect Gremlin certificate files
GREMLIN_CERT_FILE=$(ls -1 ${GREMLIN_CERT_PATH}/*cert.pem | head -n 1)
GREMLIN_KEY_FILE=$(ls -1 ${GREMLIN_CERT_PATH}/*key.pem | head -n 1)

# Create a Gremlin namespace and secret
kubectl create ns gremlin
kubectl -n gremlin create secret generic gremlin-team-cert \
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
	--set gremlin.container.driver=containerd-runc

# Deploy an Nginx Ingress controller and wait for it to rollout
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx

# Deploy the demo application
kubectl create ns microservices-demo
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml -n microservices-demo
kubectl apply -f microservices-demo-ingress.yaml -n microservices-demo