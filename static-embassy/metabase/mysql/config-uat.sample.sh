#!/bin/bash

export NAMESPACE="mykrobe-insight-uat"
export PREFIX="mykrobe"
export MYSQL_IMAGE="mysql:5.7.28"
export DATABASE="mykrobe"
export DB_USER="mykrobe"
export DB_PASSWORD=`echo -n <DB_PASSWORD> | base64`
export ROOT_PASSWORD=`echo -n <ROOT_PASSWORD> | base64`

sh ./deploy-mysql.sh