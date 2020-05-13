kubectl delete -f atlas-keycloak-ingress.json
kubectl delete -f atlas-keycloak-deployment.json
kubectl delete -f atlas-keycloak-service.json

kubectl create -f atlas-keycloak-service.json
kubectl create -f atlas-keycloak-deployment.json
kubectl create -f atlas-keycloak-ingress.json