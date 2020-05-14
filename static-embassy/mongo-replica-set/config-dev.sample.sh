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

sh ./deploy-mongo.sh