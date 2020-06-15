#!/bin/bash

export NAMESPACE="insight-dev"
export PREFIX="mykrobe"
export CONFLUENT="$PREFIX-confluent"
export ZOOKEEPER="zookeeper"
export SCHEMA_REGISTRY="schema-registry"
export KAFKA_CONNECT="kafka-connect"
export KAFKA="kafka"
export CONTROL_CENTER_IMAGE="confluentinc/cp-enterprise-control-center:5.4.1"
export KAFKA_CONNECT_IMAGE="makeandship/kafka-connect"
export SCHEMA_REGISTRY_IMAGE="confluentinc/cp-schema-registry:5.4.1"
export KAFKA_BROKER_IMAGE="confluentinc/cp-enterprise-kafka:5.4.1"
export ZOOKEEPER_IMAGE="confluentinc/cp-zookeeper:5.4.1"

# Pod (Deployment) resource limits
export REQUEST_ZOOKEEPER_CPU="500m"
export REQUEST_ZOOKEEPER_MEMORY="1Gi"
export REQUEST_ZOOKEEPER_STORAGE="50Gi"
export LIMIT_ZOOKEEPER_CPU="1000m"
export LIMIT_ZOOKEEPER_MEMORY="1Gi"
export LIMIT_ZOOKEEPER_STORAGE="100Gi"
export ZOOKEEPER_EPHERMERAL_STORAGE="4Gi"

export REQUEST_KAFKA_CPU="1000m"
export REQUEST_KAFKA_MEMORY="2Gi"
export REQUEST_KAFKA_STORAGE="50Gi"
export LIMIT_KAFKA_CPU="2000m"
export LIMIT_KAFKA_MEMORY="4Gi"
export LIMIT_KAFKA_STORAGE="100Gi"
export KAFKA_EPHERMERAL_STORAGE="4Gi"

export REQUEST_SCHEMA_REGISTRY_CPU="500m"
export REQUEST_SCHEMA_REGISTRY_MEMORY="1Gi"
export LIMIT_SCHEMA_REGISTRY_CPU="1000m"
export LIMIT_SCHEMA_REGISTRY_MEMORY="1Gi"

export REQUEST_KAFKA_CONNECT_CPU="1000m"
export REQUEST_KAFKA_CONNECT_MEMORY="1Gi"
export LIMIT_KAFKA_CONNECT_CPU="2000m"
export LIMIT_KAFKA_CONNECT_MEMORY="2Gi"

sh ./deploy-confluent.sh