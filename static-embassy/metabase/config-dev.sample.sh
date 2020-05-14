#!/bin/bash

export NAMESPACE="mykrobe-insight-dev"
export PREFIX="mykrobe"
export METABASE_IMAGE="metabase/metabase:v0.34.3"
export DATABASE="mykrobe"
export DB_USER=`echo -n "mykrobe" | base64`
export DB_PASSWORD=`echo -n <DB_PASSWORD> | base64`
export DNS="insight-dev.mykro.be"
export APP_NAME="insight-dev"

sh ./deploy-metabase.sh