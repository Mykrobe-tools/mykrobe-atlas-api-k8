#!/usr/bin/env bash

# --------------------------------------------------------------
# Automated deployment using the kubernetes API:

# - MongoDB: Replication Controller
# - MongoDB: Service
# - MongoDB: Ingress (not autodeployed or used)
# - MongoDB: PVC (not autodeployed)

# - API: Deployment
# - API: Service
# - API: Ingress
# - API: PVC (not autodeployed)
# --------------------------------------------------------------

sed -i "s~#{ARTIFACT_IMAGE}~$DOCKERHUB_ORGANISATION/atlas-keycloak:$GO_DEPENDENCY_LABEL_BUILD~g" keycloak/atlas-keycloak-deployment.json

sed -i "s~#{KEYCLOAK_DB_VENDOR}~$KEYCLOAK_DB_VENDOR~g" keycloak/atlas-keycloak-deployment.json
sed -i "s~#{KEYCLOAK_DB_ADDR}~$KEYCLOAK_DB_ADDR~g" keycloak/atlas-keycloak-deployment.json
sed -i "s~#{KEYCLOAK_DB_DATABASE}~$KEYCLOAK_DB_DATABASE~g" keycloak/atlas-keycloak-deployment.json
sed -i "s~#{KEYCLOAK_DB_PORT}~$KEYCLOAK_DB_PORT~g" keycloak/atlas-keycloak-deployment.json
sed -i "s~#{KEYCLOAK_DB_USER}~$KEYCLOAK_DB_USER~g" keycloak/atlas-keycloak-deployment.json
sed -i "s~#{KEYCLOAK_DB_PASSWORD}~$KEYCLOAK_DB_PASSWORD~g" keycloak/atlas-keycloak-deployment.json
sed -i "s~#{KEYCLOAK_USER}~$KEYCLOAK_USER~g" keycloak/atlas-keycloak-deployment.json
sed -i "s~#{KEYCLOAK_PASSWORD}~$KEYCLOAK_PASSWORD~g" keycloak/atlas-keycloak-deployment.json
sed -i "s~#{PROXY_ADDRESS_FORWARDING}~$PROXY_ADDRESS_FORWARDING~g" keycloak/atlas-keycloak-deployment.json

if [ -z $KUBE_TOKEN ]; then
  echo "FATAL: Environment Variable KUBE_TOKEN must be specified."
  exit ${2:-1}
fi

if [ -z $NAMESPACE ]; then
  echo "FATAL: Environment Variable NAMESPACE must be specified."
  exit ${2:-1}
fi

if [ -z $KUBERNETES_SERVICE_HOST ]; then
  echo "FATAL: Environment Variable KUBERNETES_SERVICE_HOST must be specified."
  exit ${2:-1}
fi

if [ -z $KUBERNETES_PORT_443_TCP_PORT ]; then
  echo "FATAL: Environment Variable KUBERNETES_PORT_443_TCP_PORT must be specified."
  exit ${2:-1}
fi

# --------------------------------------------------------------

echo
echo "Deploying Keycloak using $DOCKERHUB_ORGANISATION/atlas-keycloak:$GO_DEPENDENCY_LABEL_BUILD"

# --------------------------------------------------------------

status_code=$(curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/apis/apps/v1beta2/namespaces/$NAMESPACE/deployments/atlas-keycloak-deployment" \
    -X GET -o /dev/null -w "%{http_code}")

echo
echo "Keycloak deployment: $status_code"

if [ $status_code == 200 ]; then
  echo "Updating deployment"
  echo

  curl -H 'Content-Type: application/strategic-merge-patch+json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/apis/apps/v1beta2/namespaces/$NAMESPACE/deployments/atlas-keycloak-deployment" \
    -X PATCH -d @keycloak/atlas-keycloak-deployment.json
else
  echo "Creating deployment"
  echo

  curl -H 'Content-Type: application/json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/apis/apps/v1beta2/namespaces/$NAMESPACE/deployments" \
    -X POST -d @keycloak/atlas-keycloak-deployment.json
fi

echo