#!/bin/bash

export NAMESPACE="mykrobe-dev"
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