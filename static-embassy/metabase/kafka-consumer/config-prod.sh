#!/bin/bash

export NAMESPACE="mykrobe-insight-prod"
export PREFIX="mykrobe"
export CONSUMER_IMAGE="makeandship/atlas-kafka-consumer:1.0.0"
export APP_NAME="kafka-consumer"
export BROKER_URL="http://mykrobe-confluent-kafka-0-nodeport.mykrobe-insight-prod.svc.cluster.local:33090"
export SCHEMA_REGISTRY_URL="http://mykrobe-confluent-schema-registry.mykrobe-insight-prod.svc.cluster.local:8081"

sh ./deploy.sh