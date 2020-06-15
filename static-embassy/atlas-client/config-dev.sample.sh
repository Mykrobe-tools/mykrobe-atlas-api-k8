#!/bin/bash

export NAMESPACE="mykrobe-dev"
export PREFIX="atlas"
export CLIENT_IMAGE="eu.gcr.io/atlas-275810/mykrobe-atlas:v0.0.8"
export HOST="dev.mykro.be"
export NODE_OPTIONS_MEMORY="4096"

# Pod (Deployment) resource limits
export REQUEST_CPU="1000m"
export REQUEST_MEMORY="1Gi"
export REQUEST_STORAGE="2Gi"
export LIMIT_CPU="1000m"
export LIMIT_MEMORY="1Gi"
export LIMIT_STORAGE="4Gi"

# Env vars

# Endpoint of the API
export REACT_APP_API_URL="https://api-dev.mykro.be"

# Swagger spec if available
export REACT_APP_API_SPEC_URL="https://api-dev.mykro.be/swagger.json"

# Universal cookie name, used to store auth token if not using Keycloak
export REACT_APP_TOKEN_STORAGE_KEY="dev.mykro.be"

# If using Keycloak
export REACT_APP_KEYCLOAK_URL="https://accounts-dev.mykro.be/auth"
export REACT_APP_KEYCLOAK_REALM="atlas"
export REACT_APP_KEYCLOAK_CLIENT_ID="react-web-client"
export REACT_APP_KEYCLOAK_IDP=

# Provider upload keys
export REACT_APP_GOOGLE_MAPS_API_KEY=`echo -n "" | base64`
export REACT_APP_BOX_CLIENT_ID=`echo -n "" | base64`
export REACT_APP_DROPBOX_APP_KEY=`echo -n "" | base64`
export REACT_APP_GOOGLE_DRIVE_CLIENT_ID=`echo -n "" | base64`
export REACT_APP_GOOGLE_DRIVE_DEVELOPER_KEY=`echo -n "" | base64`
export REACT_APP_ONEDRIVE_CLIENT_ID=`echo -n "" | base64`
sh ./deploy-client.sh