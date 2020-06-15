#!/bin/bash

export NAMESPACE="mykrobe-dev"
export PREFIX="atlas"
export CLIENT_IMAGE="eu.gcr.io/atlas-275810/mykrobe-atlas:v0.0.7"
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
REACT_APP_API_URL=

# Swagger spec if available
REACT_APP_API_SPEC_URL=

# Universal cookie name, used to store auth token if not using Keycloak
REACT_APP_TOKEN_STORAGE_KEY=

# If using Keycloak
REACT_APP_KEYCLOAK_URL=
REACT_APP_KEYCLOAK_REALM=
REACT_APP_KEYCLOAK_CLIENT_ID=
REACT_APP_KEYCLOAK_IDP=

# Provider upload keys
REACT_APP_GOOGLE_MAPS_API_KEY=
REACT_APP_BOX_CLIENT_ID=
REACT_APP_DROPBOX_APP_KEY=
REACT_APP_GOOGLE_DRIVE_CLIENT_ID=
REACT_APP_GOOGLE_DRIVE_REACT_APP_GOOGLE_DRIVE_DEVELOPER_KEY=
REACT_APP_ONEDRIVE_CLIENT_ID=

sh ./deploy-client.sh