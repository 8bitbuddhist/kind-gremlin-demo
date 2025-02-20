#!/usr/bin/env bash
kubectl delete ns bank-of-anthos
kubectl create ns bank-of-anthos
kubectl apply -f bank-of-anthos/extras/jwt/jwt-secret.yaml -n bank-of-anthos
kubectl apply -f bank-of-anthos/kubernetes-manifests/ -n bank-of-anthos

# Increase user session timeout to one year
kubectl set env deployment/userservice TOKEN_EXPIRY_SECONDS=31536000 -n bank-of-anthos

# Deploy ingress controller
kubectl apply -f bank-of-anthos-ingress.yaml -n bank-of-anthos

./scale.sh
