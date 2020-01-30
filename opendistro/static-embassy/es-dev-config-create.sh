kubectl delete secret es-dev-config 
kubectl create secret generic es-dev-config \
    --from-file=config.yml=config.yml \
    --from-file=custom-elasticsearch.yml=custom-elasticsearch.yml \
    --namespace default