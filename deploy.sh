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

sed -i "s~#{ARTIFACT_IMAGE}~makeandship/atlas-api:$GO_PIPELINE_LABEL~g" atlas-api-deployment.json
sed -i "s~#{MONGO_USER}~$MONGO_USER~g" atlas-api-deployment.json
sed -i "s~#{MONGO_PASSWORD}~$MONGO_PASSWORD~g" atlas-api-deployment.json
sed -i "s~#{AWS_ACCESS_KEY}~$AWS_ACCESS_KEY~g" atlas-api-deployment.json
sed -i "s~#{AWS_SECRET_KEY}~$AWS_SECRET_KEY~g" atlas-api-deployment.json
sed -i "s~#{AWS_REGION}~$AWS_REGION~g" atlas-api-deployment.json
sed -i "s~#{ATLAS_APP}~$ATLAS_APP~g" atlas-api-deployment.json
sed -i "s~#{ES_SCHEME}~$ES_SCHEME~g" atlas-api-deployment.json
sed -i "s~#{ES_HOST}~$ES_HOST~g" atlas-api-deployment.json
sed -i "s~#{ES_PORT}~$ES_PORT~g" atlas-api-deployment.json
sed -i "s~#{ES_USERNAME}~$ES_USERNAME~g" atlas-api-deployment.json
sed -i "s~{{ES_PASSWORD}}~$ES_PASSWORD~g" atlas-api-deployment.json
sed -i "s~#{ES_INDEX_NAME}~$ES_INDEX_NAME~g" atlas-api-deployment.json
sed -i "s~#{KEYCLOAK_REDIRECT_URI}~$KEYCLOAK_REDIRECT_URI~g" atlas-api-deployment.json
sed -i "s~#{API_HOST}~$API_HOST~g" atlas-api-deployment.json
sed -i "s~#{DEBUG}~$DEBUG~g" atlas-api-deployment.json
sed -i "s~#{ANALYSIS_API}~$ANALYSIS_API~g" atlas-api-deployment.json
sed -i "s~#{BIGSI_API}~$BIGSI_API~g" atlas-api-deployment.json
sed -i "s~#{UPLOADS_LOCATION}~$UPLOADS_LOCATION~g" atlas-api-deployment.json
sed -i "s~#{DEMO_DATA_ROOT_FOLDER}~$DEMO_DATA_ROOT_FOLDER~g" atlas-api-deployment.json
sed -i "s~#{LOCATIONIQ_API_KEY}~$LOCATIONIQ_API_KEY~g" atlas-api-deployment.json


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
echo "Deploying MongoDB"
echo

# --------------------------------------------------------------

status_code=$(curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$NAMESPACE/replicationcontrollers/db-controller" \
    -X GET -o /dev/null -w "%{http_code}")

echo "MongoDB replication controller $status_code"

if [ $status_code == 200 ]; then
  echo "Updating MongoDB replication controller"
  echo
  
  curl -H 'Content-Type: application/strategic-merge-patch+json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$NAMESPACE/replicationcontrollers/db-controller" \
    -X PATCH -d @atlas-api-mongodb-replicationcontroller.json
else
 echo "Creating MongoDB replication controller"
 echo
  
 curl -H 'Content-Type: application/json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$NAMESPACE/replicationcontrollers" \
    -X POST -d @atlas-api-mongodb-replicationcontroller.json
fi

echo

# --------------------------------------------------------------

status_code=$(curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$NAMESPACE/services/db" \
    -X GET -o /dev/null -w "%{http_code}")

echo
echo "MongoDB service: $status_code"

if [ $status_code == 200 ]; then
  echo "Updating service for mongodb"
  echo

  curl -H 'Content-Type: application/strategic-merge-patch+json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$NAMESPACE/services/db" \
    -X PATCH -d @atlas-api-mongodb-service.json
else
  echo "Creating service for mongodb"
  echo

  curl -H 'Content-Type: application/json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$NAMESPACE/services" \
    -X POST -d @atlas-api-mongodb-service.json
fi

echo

# --------------------------------------------------------------

echo
echo "Deploying API using $ARTIFACT_IMAGE"

# --------------------------------------------------------------

status_code=$(curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/apis/apps/v1beta2/namespaces/$NAMESPACE/deployments/atlas-api-deployment" \
    -X GET -o /dev/null -w "%{http_code}")

echo
echo "API deployment: $status_code"

if [ $status_code == 200 ]; then
  echo "Updating deployment"
  echo

  curl -H 'Content-Type: application/strategic-merge-patch+json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/apis/apps/v1beta2/namespaces/$NAMESPACE/deployments/atlas-api-deployment" \
    -X PATCH -d @atlas-api-deployment.json
else
  echo "Creating deployment"
  echo

  curl -H 'Content-Type: application/json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/apis/apps/v1beta2/namespaces/$NAMESPACE/deployments" \
    -X POST -d @atlas-api-deployment.json
fi

echo

# --------------------------------------------------------------

status_code=$(curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$NAMESPACE/services/atlas-api-service" \
    -X GET -o /dev/null -w "%{http_code}")

echo
echo "API service: $status_code"

if [ $status_code == 200 ]; then
 echo "Updating API service"
 echo

 curl -H 'Content-Type: application/strategic-merge-patch+json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$NAMESPACE/services/atlas-api-service" \
    -X PATCH -d @atlas-api-service.json
else
 echo "Creating API service"
 echo

 curl -H 'Content-Type: application/json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$NAMESPACE/services" \
    -X POST -d @atlas-api-service.json

fi

echo

# --------------------------------------------------------------

status_code=$(curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/apis/extensions/v1beta1/namespaces/$NAMESPACE/ingresses/atlas-api-ingress" \
    -X GET -o /dev/null -w "%{http_code}")

echo "API Ingress: $status_code"

if [ $status_code == 200 ]; then
 echo "Updating ingress"
 echo

 curl -H 'Content-Type: application/strategic-merge-patch+json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/apis/extensions/v1beta1/namespaces/$NAMESPACE/ingresses/atlas-api-ingress" \
    -X PATCH -d @atlas-api-ingress.json
else
  echo "Creating ingress"
  echo

  curl -H 'Content-Type: application/json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/apis/extensions/v1beta1/namespaces/$NAMESPACE/ingresses" \
    -X POST -d @atlas-api-ingress.json
fi

echo