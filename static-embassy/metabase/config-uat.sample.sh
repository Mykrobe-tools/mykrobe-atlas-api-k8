#!/bin/bash

export NAMESPACE="mykrobe-insight-uat"
export PREFIX="mykrobe"
export METABASE_IMAGE="metabase/metabase:v0.34.3"
export DATABASE="metabase"
export DB_USER=`echo -n "mykrobe" | base64`
export DB_PASSWORD=`echo -n "FD7tQNctPRk64pLv" | base64`
export DNS="insight-uat.mykro.be"
export APP_NAME="insight-uat"

sh ./deploy-metabase.sh