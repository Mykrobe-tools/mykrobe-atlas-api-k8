#!/bin/bash

kubectl create secret docker-registry gcr-json-key \
	--docker-server=eu.gcr.io \
	--docker-username=_json_key \
	--docker-password="$(cat ./atlas-275810-1b85bf39eb34.json)" \
	--docker-email=mark@makeandship.com \
	--namespace=mykrobe-dev 