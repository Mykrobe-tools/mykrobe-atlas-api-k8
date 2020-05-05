#!/bin/bash

export NAMESPACE="mykrobe-dev"
export PREFIX="mykrobe"
export MYSQL_IMAGE="mysql:5.7.28"
export DATABASE="mykrobe"
export DB_USER="mykrobe"
export DB_PASSWORD=`echo -n "FD7tQNctPRk64pLv" | base64`
export ROOT_PASSWORD=`echo -n "4CLh97xZADxN4tPC" | base64`