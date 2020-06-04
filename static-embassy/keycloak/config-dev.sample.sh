#!/bin/bash

export NAMESPACE="mykrobe-dev"
export POSTGRES_IMAGE="postgres:10"
export KEYCLOAK_IMAGE="makeandship/keycloak:1"
export ENV="dev"
export HOST="accounts-dev.mykro.be"
export POSTGRES_DB="keycloak"
export POSTGRES_USER="keycloak"
export POSTGRES_PASSWORD="<POSTGRES_PASSWORD>"
export DB_ADDR="keycloak-postgres"
export DB_PORT="5432"
export KEYCLOAK_USER="admin"
export KEYCLOAK_PASSWORD="<KEYCLOAK_PASSWORD>"

sh ./deploy-keycloak.sh