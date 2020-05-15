#!/bin/bash

export NAMESPACE="mykrobe-search-prod"
export APPLICATION_NAME="mykrobe-opendistro-es"
export RELEASE_NAME="mykrobe"
export OPENDISTRO_IMAGE="amazon/opendistro-for-elasticsearch:1.6.0"
export KIBANA_IMAGE="amazon/opendistro-for-elasticsearch-kibana:1.6.0"

sh ./deploy-es.sh