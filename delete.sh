#!/usr/bin/env bash

# DIR where the current script resides
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

kubectl delete -k ${DIR}/mykrobe-atlas-api-k8/static-embassy
kubectl delete -k ${DIR}/mykrobe-atlas-k8/static-embassy
kubectl delete -k ${DIR}/mykrobe-atlas-analysis-api/k8

kubectl delete secret/dockerhub

kubectl get pv
kubectl get all