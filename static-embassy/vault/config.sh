#!/bin/bash

export NAMESPACE="shared"
export PREFIX="vault"
export IMAGE_NAME="vault:1.4.0"

export REQUEST_MEMORY="1Gi"
export REQUEST_CPU="500m"
export LIMIT_MEMORY="1Gi"
export LIMIT_CPU="1000m"
export EPHERMERAL_STORAGE="2Gi"
export REQUEST_STORAGE="10Gi"
export LIMIT_STORAGE="20Gi"

echo ""
echo "Deploying vault using:"
echo " - NAMESPACE: $NAMESPACE"
echo " - Prefix: $PREFIX"
echo " - Image: $IMAGE_NAME"
echo ""

echo "Limits:"
echo " - Request Memory: $REQUEST_MEMORY"
echo " - Request CPU: $REQUEST_CPU"
echo " - Limit Memory: $LIMIT_MEMORY"
echo " - Limit CPU: $LIMIT_CPU"
echo " - Ephermeral Storage: $EPHERMERAL_STORAGE"
echo " - Request Storage: $REQUEST_STORAGE"
echo " - Limit Strorage: $LIMIT_STORAGE"
echo ""

sh ./deploy-vault.sh