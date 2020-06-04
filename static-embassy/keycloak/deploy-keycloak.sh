#!/bin/bash

echo ""
echo "Deploying atlas api using:"
echo " - Namespace: $NAMESPACE"
echo " - Postgres image: $POSTGRES_IMAGE"
echo " - Keycloak image: $KEYCLOAK_IMAGE"
echo " - ENV: $ENV"
echo " - Host: $HOST"
echo " - Postgres db name: $POSTGRES_DB"
echo " - Postgres user: $POSTGRES_USER"
echo " - Postgres password: $POSTGRES_PASSWORD"
echo " - DB address: $DB_ADDR"
echo " - DB port: $DB_PORT"
echo " - Keycloak admin user: $KEYCLOAK_USER"
echo " - Keycloak admin password: $KEYCLOAK_PASSWORD"
echo ""

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
  namespace: $NAMESPACE
  labels:
    app: postgres
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: keycloak-theme-data
  namespace: $NAMESPACE
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 2Gi
---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  labels:
    app: postgres
  name: keycloak-postgres
  namespace: $NAMESPACE
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - image: $POSTGRES_IMAGE
        name: postgres
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5432
          protocol: TCP
        volumeMounts:
        - mountPath: "/var/lib/postgresql/data"
          name: postgresdb
        env:
        - name: POSTGRES_DB
          value: $POSTGRES_DB
        - name: POSTGRES_USER
          value: $POSTGRES_USER
        - name: POSTGRES_PASSWORD
          value: $POSTGRES_PASSWORD
      volumes:
      - name: postgresdb
        persistentVolumeClaim:
          claimName: postgres-data
---
apiVersion: v1
kind: Service
metadata:
  name: keycloak-postgres
  namespace: $NAMESPACE
  labels:
    app: postgres
spec:
  type: NodePort
  ports:
  - protocol: TCP
    port: 5432
    targetPort: 5432
  selector:
    app: postgres
---
apiVersion: v1
kind: Service
metadata:
  name: keycloak-service
  namespace: $NAMESPACE
spec:
  type: NodePort
  ports:
  - name: http
    port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: keycloak
---
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  labels:
    app: keycloak
  name: keycloak-deployment
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
      - image: $KEYCLOAK_IMAGE
        name: keycloak
        ports:
        - containerPort: 8080
          protocol: TCP
        volumeMounts:
        - mountPath: "/opt/jboss/keycloak/themes/mykrobe"
          name: keycloak-theme-volume
        env:
        - name: DB_VENDOR
          value: POSTGRES
        - name: DB_ADDR
          value: $DB_ADDR
        - name: DB_DATABASE
          value: keycloak
        - name: DB_PORT
          value: $DB_PORT
        - name: DB_USER
          value: $POSTGRES_USER
        - name: DB_PASSWORD
          value: $POSTGRES_PASSWORD
        - name: KEYCLOAK_USER
          value: $KEYCLOAK_USER
        - name: KEYCLOAK_PASSWORD
          value: $KEYCLOAK_PASSWORD
        - name: PROXY_ADDRESS_FORWARDING
          value: 'true'
      volumes:
      - name: keycloak-theme-volume
        persistentVolumeClaim:
          claimName: keycloak-theme-data
      imagePullSecrets:
      - name: dockerhub
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: atlas-keycloak-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
  namespace: $NAMESPACE
spec:
  backend:
    serviceName: keycloak-service
    servicePort: 8080
  tls:
  - hosts:
    - $HOST
    secretName: accounts-$ENV-mykro-be-tls
  rules:
  - host: $HOST
    http:
      paths:
      - backend:
          serviceName: keycloak-service
          servicePort: 8080
EOF