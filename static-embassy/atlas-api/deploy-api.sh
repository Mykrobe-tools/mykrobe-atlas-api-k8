#!/bin/bash

echo ""
echo "Deploying atlas api using:"
echo " - Namespace: $NAMESPACE"
echo " - Env: $ENV"
echo " - Api Image: $API_IMAGE"
echo " - DB Host: $DB_SERVICE_HOST"
echo " - DB rs name: $DB_RS_NAME"
echo " - Mongo user: $MONGO_USER"
echo " - Mongo password: $MONGO_PASSWORD"
echo " - AWS access key: $AWS_ACCESS_KEY"
echo " - AWS secret key: $AWS_SECRET_KEY"
echo " - AWS region: $AWS_REGION"
echo " - Atlas app: $ATLAS_APP"
echo " - ES schema: $ES_SCHEME"
echo " - ES host: $ES_HOST"
echo " - ES port: $ES_PORT"
echo " - ES username: $ES_USERNAME"
echo " - ES password: $ES_PASSWORD"
echo " - ES index name: $ES_INDEX_NAME"
echo " - Keycloak redirect uri: $KEYCLOAK_REDIRECT_URI"
echo " - Keycloak url: $KEYCLOAK_URL"
echo " - Keycloak admin password: $KEYCLOAK_ADMIN_PASSWORD"
echo " - API host: $API_HOST"
echo " - Debug: $DEBUG"
echo " - Analysis api: $ANALYSIS_API"
echo " - Bigsi api: $BIGSI_API"
echo " - Uploads location: $UPLOADS_LOCATION"
echo " - Demo data folder: $DEMO_DATA_ROOT_FOLDER"
echo " - Location IQ api key: $LOCATIONIQ_API_KEY"
echo ""

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-data
  namespace: $NAMESPACE
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 8Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: uploads-data
  namespace: $NAMESPACE
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 30Gi
---
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  labels:
    app: atlas-api
  name: atlas-api-Deployment
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: atlas-api
  template:
    metadata:
      labels:
        app: atlas-api
    spec:
      containers:
      - image: $API_IMAGE
        name: atlas-api
        ports:
        - containerPort: 3000
          protocol: TCP
        volumeMounts:
        - mountPath: "/app/uploads"
          name: uploads-volume
        - mountPath: "/app/demo"
          name: demo-volume
        env:
        - name: NODE_ENV
          value: production
        - name: DB_SERVICE_HOST
          value: $DB_SERVICE_HOST
        - name: DB_SERVICE_PORT
          value: '27017'
        - name: DB_RS_NAME
          value: $DB_RS_NAME
        - name: MONGO_USER
          value: $MONGO_USER
        - name: MONGO_PASSWORD
          value: $MONGO_PASSWORD
        - name: AWS_ACCESS_KEY
          value: $AWS_ACCESS_KEY
        - name: AWS_SECRET_KEY
          value: $AWS_SECRET_KEY
        - name: AWS_REGION
          value: $AWS_REGION
        - name: ATLAS_APP
          value: $ATLAS_APP
        - name: ES_SCHEME
          value: $ES_SCHEME
        - name: ES_HOST
          value: $ES_HOST
        - name: ES_PORT
          value: $ES_PORT
        - name: ES_USERNAME
          value: $ES_USERNAME
        - name: ES_PASSWORD
          value: $ES_PASSWORD
        - name: ES_INDEX_NAME
          value: $ES_INDEX_NAME
        - name: KEYCLOAK_REDIRECT_URI
          value: $KEYCLOAK_REDIRECT_URI
        - name: KEYCLOAK_URL
          value: $KEYCLOAK_URL
        - name: KEYCLOAK_ADMIN_PASSWORD
          value: $KEYCLOAK_ADMIN_PASSWORD
        - name: API_HOST
          value: $API_HOST
        - name: DEBUG
          value: $DEBUG
        - name: ANALYSIS_API
          value: $ANALYSIS_API
        - name: BIGSI_API
          value: $BIGSI_API
        - name: UPLOADS_LOCATION
          value: $UPLOADS_LOCATION
        - name: DEMO_DATA_ROOT_FOLDER
          value: $DEMO_DATA_ROOT_FOLDER
        - name: LOCATIONIQ_API_KEY
          value: $LOCATIONIQ_API_KEY
      volumes:
      - name: uploads-volume
        persistentVolumeClaim:
          claimName: uploads-data
      - name: demo-volume
        persistentVolumeClaim:
          claimName: demo-data
      imagePullSecrets:
      - name: dockerhub
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: atlas-api-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/enable-cors: 'true'
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    nginx.ingress.kubernetes.io/proxy-body-size: 10m
  namespace: $NAMESPACE
spec:
  backend:
    serviceName: atlas-api-service
    servicePort: 3000
  tls:
  - hosts:
    - $API_HOST
    secretName: api-$ENV-mykro-be-tls
  rules:
  - host: $API_HOST
    http:
      paths:
      - backend:
          serviceName: atlas-api-service
          servicePort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: atlas-api-service
  namespace: $NAMESPACE
spec:
  type: NodePort
  ports:
  - name: http
    port: 3000
    protocol: TCP
    targetPort: 3000
  selector:
    app: atlas-api
EOF