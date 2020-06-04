#!/bin/bash

export NAMESPACE="mykrobe-dev"
export PREFIX="keycloak"
export POSTGRES_IMAGE="postgres:10"
export KEYCLOAK_IMAGE="makeandship/keycloak:1"
export HOST="accounts-dev.mykro.be"
export POSTGRES_DB="keycloak"
export POSTGRES_USER="keycloak"
export POSTGRES_PASSWORD="<POSTGRES_PASSWORD>"
export DB_ADDR="keycloak-postgres"
export DB_PORT="5432"
export KEYCLOAK_USER="admin"
export KEYCLOAK_PASSWORD="<KEYCLOAK_PASSWORD>"

# Storage sizes
export STORAGE_POSTGRES="10Gi"
export STORAGE_THEMES="2Gi"

sh ./deploy-keycloak.sh