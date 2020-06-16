#!/bin/bash

export NAMESPACE="insight-dev"
export PREFIX="mykrobe"
export CONSUMER_IMAGE="eu.gcr.io/atlas-275810/mykrobe-atlas-kafka-consumer:v0.0.1"
export APP_NAME="kafka-consumer"
export BROKER_URL="http://mykrobe-confluent-kafka.insight-dev.svc.cluster.local:9092"
export SCHEMA_REGISTRY_URL="http://mykrobe-confluent-schema-registry.insight-dev.svc.cluster.local:8081"


# Pod (Deployment) resource limits
export REQUEST_CPU="500m"
export REQUEST_MEMORY="2Gi"
export REQUEST_STORAGE="2Gi"
export LIMIT_CPU="1000m"
export LIMIT_MEMORY="2Gi"
export LIMIT_STORAGE="4Gi"

sh ./deploy.sh