#!/bin/bash

source config.sh

echo ""
echo "Deploying Kafka consumer using:"
echo " - NAMESPACE: $NAMESPACE"
echo " - PREFIX: $PREFIX"
echo " - App Name: $APP_NAME"
echo " - Broker: $BROKER_URL"
echo " - Schema Registry: $SCHEMA_REGISTRY_URL"
echo " - Consumer Image: $CONSUMER_IMAGE"
echo ""

cat <<EOF | kubectl apply -f -
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: $PREFIX-$APP_NAME
  namespace: $NAMESPACE
  labels:
    app: $PREFIX-$APP_NAME
spec:
  selector:
    matchLabels:
      app: $PREFIX-$APP_NAME
  replicas: 1
  template:
    metadata:
      labels:
        app: $PREFIX-$APP_NAME
    spec:
      serviceAccountName: $PREFIX-insight
      containers:
        - name: kafka-consumer
          image: $CONSUMER_IMAGE
          imagePullPolicy: IfNotPresent
          env:
          - name: BROKER_URL
            value: $BROKER_URL
          - name: SCHEMA_REGISTRY_URL
            value: $SCHEMA_REGISTRY_URL
      imagePullSecrets:
        - name: dockerhub
EOF
