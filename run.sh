#!/bin/bash
source .env

kind delete cluster --name ${KIND_CLUSTER_NAME}
kind create cluster --name ${KIND_CLUSTER_NAME} --config config.yaml

kubectl create ns gremlin
kubectl -n gremlin create secret generic gremlin-team-cert \
	--from-file=${GREMLIN_CERT_PATH}/gremlin.cert \
	--from-file=${GREMLIN_CERT_PATH}/gremlin.key \
	--from-literal=GREMLIN_TEAM_ID=${GREMLIN_TEAM_ID} \
	--from-literal=GREMLIN_CLUSTER_ID=${GREMLIN_CLUSTER_ID}

helm repo add gremlin https://helm.gremlin.com
helm install gremlin gremlin/gremlin \
	--namespace gremlin \
	--set gremlin.secret.name=gremlin-team-cert \
	--set gremlin.hostPID=true \
	--set gremlin.container.driver=containerd-runc

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
kubectl wait --for=condition=available deployment/ingress-nginx-controller -n ingress-nginx
kubectl creates ns microservices-demo
kubectl apply -f microservices-demo/release/kubernetes-manifests.yaml -n microservices-demo