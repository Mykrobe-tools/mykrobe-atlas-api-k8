#!/bin/bash

export NAMESPACE="mykrobe-dev"
export PREFIX="atlas"
export CLIENT_IMAGE="makeandship/atlas-client:18"
export HOST="dev.mykro.be"
export NODE_OPTIONS_MEMORY="4096"


# Pod (Deployment) resource limits
export REQUEST_CPU="1000m"
export REQUEST_MEMORY="1Gi"
export REQUEST_STORAGE="2Gi"
export LIMIT_CPU="1000m"
export LIMIT_MEMORY="1Gi"
export LIMIT_STORAGE="4Gi"

sh ./deploy-client.sh