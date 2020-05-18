#!/bin/bash

export NAMESPACE="mykrobe-analysis-uat"
export TARGET_ENV="uat"
export ATLAS_API="https://api-uat.mykro.be"
export ANALYSIS_API_IMAGE="phelimb/mykrobe-atlas-analysis-api:113af42"
export ANALYSIS_CONFIG_HASH_MD5="0960112ac0a45b542a3c77aea5f2ceb4"
export ANALYSIS_API_DNS="analysis-uat.mykro.be"
export BIGSI_AGGREGATOR_IMAGE="phelimb/bigsi-aggregator:210419"
export BIGSI_CONFIG_HASH_MD5="8240ad548481b94901c8052723816e27"
export BIGSI_IMAGE="phelimb/bigsi:v0.3.5"
export BIGSI_DNS="bigsi-uat.mykro.be"
export DISTANCE_API_IMAGE="iqballab/distance-service:latest"
export REDIS_IMAGE="redis:4.0"

echo ""
echo "Deploying analysis api using:"
echo " - NAMESPACE: $NAMESPACE"
echo " - Target: $TARGET_ENV"
echo " - Atlas Api: $ATLAS_API"
echo " - Analysis image: $ANALYSIS_API_IMAGE"
echo " - Bigsi aggregator image: $BIGSI_AGGREGATOR_IMAGE"
echo " - Bigsi image: $BIGSI_IMAGE"
echo " - Analysis config hash: $ANALYSIS_CONFIG_HASH_MD5"
echo " - DNS: $ANALYSIS_API_DNS"
echo " - Bigsi config hash: $BIGSI_CONFIG_HASH_MD5"
echo " - Bigsi dns: $BIGSI_DNS"
echo " - Distance api image: $DISTANCE_API_IMAGE"
echo " - Redis image: $REDIS_IMAGE"
echo ""

sh ./redis/deploy-redis.sh
sh ./analysis/deploy-analysis.sh
sh ./bigsi/deploy-bigsi.sh
sh ./distance/deploy-distance.sh