#!/bin/bash

export NAMESPACE="mykrobe-dev"
export MONGO_IMAGE="mongo:4.2"
export RELEASE_NAME="mykrobe"
export REPLICAS="3"
export APP_DB="atlas"
export MONGO_USER=`echo -n "admin" | base64`
export MONGO_PASSWORD=`echo -n "<password>" | base64`
export APP_USER=`echo -n "atlas" | base64`
export APP_PASSWORD=`echo -n "<password>" | base64`
export MONGO_KEY="<MONGO_KEY>"

export REQUEST_CPU="1000m"
export REQUEST_MEMORY="1Gi"
export REQUEST_STORAGE="2Gi"
export LIMIT_CPU="2000m"
export LIMIT_MEMORY="2Gi"
export LIMIT_STORAGE="4Gi"

sh ./deploy-mongo.sh