#!/bin/bash

echo ""
echo "Deploying atlas api using:"
echo " - Namespace: $NAMESPACE"
echo " - Prefix: $PREFIX"
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
echo " - Uploads temp location: $UPLOADS_TEMP_LOCATION"
echo " - Demo data folder: $DEMO_DATA_ROOT_FOLDER"
echo " - Location IQ api key: $LOCATIONIQ_API_KEY"
echo " - Swagger api files: $SWAGGER_API_FILES"
echo ""

echo "Limits:"
echo " - Request CPU: $REQUEST_CPU"
echo " - Request Memory: $REQUEST_MEMORY"
echo " - Request Storage: $REQUEST_STORAGE"
echo " - Limit CPU: $LIMIT_CPU"
echo " - Limit Memory: $LIMIT_MEMORY"
echo " - Limit Storage: $LIMIT_STORAGE"
echo ""

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $PREFIX-demo-data
  namespace: $NAMESPACE
spec:
  storageClassName: nfs-client
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: $STORAGE_DEMO
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $PREFIX-uploads-data
  namespace: $NAMESPACE
spec:
  storageClassName: nfs-client
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: $STORAGE_UPLOADS
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $PREFIX-app-data
  namespace: $NAMESPACE
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  storageClassName: nfs-client
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $PREFIX-app-tmp
  namespace: $NAMESPACE
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  storageClassName: nfs-client
---
apiVersion: v1
kind: Secret
metadata:
  name: $PREFIX-env-secret
  namespace: $NAMESPACE
data:
  MONGO_PASSWORD: $MONGO_PASSWORD
  AWS_ACCESS_KEY: $AWS_ACCESS_KEY
  AWS_SECRET_KEY: $AWS_SECRET_KEY
  ES_PASSWORD: $ES_PASSWORD
  KEYCLOAK_ADMIN_PASSWORD: $KEYCLOAK_ADMIN_PASSWORD
  LOCATIONIQ_API_KEY: $LOCATIONIQ_API_KEY
---
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  labels:
    app: $PREFIX
  name: $PREFIX-deployment
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: $PREFIX
  template:
    metadata:
      labels:
        app: $PREFIX
    spec:
      securityContext:
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
        runAsNonRoot: true
      containers:
      - image: $API_IMAGE
        name: $PREFIX
        securityContext:
          runAsUser: 1000 
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
        ports:
        - containerPort: 3000
          protocol: TCP
        volumeMounts:
        - mountPath: "/home/node/app/uploads"
          name: $PREFIX-uploads-volume
          readOnly: false 
        - mountPath: "/home/node/app/demo"
          name: $PREFIX-demo-volume
          readOnly: false 
        - mountPath: "/home/node/data/forever"
          subPath: "forever"
          name: $PREFIX-app-data
          readOnly: false 
        - mountPath: "/home/node/data/logs"
          subPath: "logs"
          name: $PREFIX-app-data
          readOnly: false 
        - mountPath: "/home/node/tmp"
          name: $PREFIX-app-tmp
          readOnly: false
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
          valueFrom:
            secretKeyRef:
              name: $PREFIX-env-secret
              key: MONGO_PASSWORD
        - name: AWS_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: $PREFIX-env-secret
              key: AWS_ACCESS_KEY
        - name: AWS_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: $PREFIX-env-secret
              key: AWS_SECRET_KEY
        - name: AWS_REGION
          value: $AWS_REGION
        - name: ATLAS_APP
          value: $ATLAS_APP
        - name: ES_SCHEME
          value: $ES_SCHEME
        - name: ES_HOST
          value: $ES_HOST
        - name: ES_PORT
          value: "$ES_PORT"
        - name: ES_USERNAME
          value: $ES_USERNAME
        - name: ES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: $PREFIX-env-secret
              key: ES_PASSWORD
        - name: ES_INDEX_NAME
          value: $ES_INDEX_NAME
        - name: KEYCLOAK_REDIRECT_URI
          value: $KEYCLOAK_REDIRECT_URI
        - name: KEYCLOAK_URL
          value: $KEYCLOAK_URL
        - name: KEYCLOAK_ADMIN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: $PREFIX-env-secret
              key: KEYCLOAK_ADMIN_PASSWORD
        - name: API_HOST
          value: $API_HOST
        - name: DEBUG
          value: "$DEBUG"
        - name: LOG_LEVEL
          value: "$LOG_LEVEL"
        - name: ANALYSIS_API
          value: $ANALYSIS_API
        - name: BIGSI_API
          value: $BIGSI_API
        - name: UPLOADS_LOCATION
          value: $UPLOADS_LOCATION
        - name: UPLOADS_TEMP_LOCATION
          value: $UPLOADS_TEMP_LOCATION
        - name: DEMO_DATA_ROOT_FOLDER
          value: $DEMO_DATA_ROOT_FOLDER
        - name: LOCATIONIQ_API_KEY
          valueFrom:
            secretKeyRef:
              name: $PREFIX-env-secret
              key: LOCATIONIQ_API_KEY
        - name: SWAGGER_API_FILES
          value: $SWAGGER_API_FILES
        - name: NODE_OPTIONS
          value: '--max-old-space-size=$NODE_OPTIONS_MEMORY'
        resources: 
          requests:
            memory: "$REQUEST_MEMORY"
            cpu: "$REQUEST_CPU" 
            ephemeral-storage: "$REQUEST_STORAGE"         
          limits:
            memory: "$LIMIT_MEMORY"
            cpu: "$LIMIT_CPU" 
            ephemeral-storage: "$LIMIT_STORAGE"
      volumes:
      - name: $PREFIX-uploads-volume
        persistentVolumeClaim:
          claimName: $PREFIX-uploads-data
      - name: $PREFIX-demo-volume
        persistentVolumeClaim:
          claimName: $PREFIX-demo-data
      - name: $PREFIX-app-data
        persistentVolumeClaim:
          claimName: $PREFIX-app-data
      - name: $PREFIX-app-tmp
        persistentVolumeClaim:
          claimName: $PREFIX-app-tmp
      imagePullSecrets:
      - name: gcr-json-key
---
apiVersion: v1
kind: Service
metadata:
  name: $PREFIX-service
  namespace: $NAMESPACE
spec:
  type: NodePort
  ports:
  - name: http
    port: 3000
    protocol: TCP
    targetPort: 3000
  selector:
    app: $PREFIX
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: $PREFIX-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/enable-cors: 'true'
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    nginx.ingress.kubernetes.io/proxy-body-size: 10m
  namespace: $NAMESPACE
spec:
  backend:
    serviceName: $PREFIX-service
    servicePort: 3000
  tls:
  - hosts:
    - $API_HOST
    secretName: $PREFIX-mykro-be-tls
  rules:
  - host: $API_HOST
    http:
      paths:
      - backend:
          serviceName: $PREFIX-service
          servicePort: 3000
EOF