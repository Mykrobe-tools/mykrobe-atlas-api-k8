#!/bin/bash

echo ""
echo "Deploying keycloak using:"
echo " - Namespace: $NAMESPACE"
echo " - Prefix: $PREFIX"
echo " - Postgres image: $POSTGRES_IMAGE"
echo " - Keycloak image: $KEYCLOAK_IMAGE"
echo " - Host: $HOST"
echo " - Postgres db name: $POSTGRES_DB"
echo " - Postgres user: $POSTGRES_USER"
echo " - Postgres password: $POSTGRES_PASSWORD"
echo " - DB address: $DB_ADDR"
echo " - DB port: $DB_PORT"
echo " - Keycloak admin user: $KEYCLOAK_USER"
echo " - Keycloak admin password: $KEYCLOAK_PASSWORD"
echo " - Postgres storage: $STORAGE_POSTGRES"
echo " - Themes storage: $STORAGE_THEMES"
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
  storageClassName: nfs-client
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: $STORAGE_POSTGRES
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $PREFIX-theme-data
  namespace: $NAMESPACE
spec:
  storageClassName: nfs-client
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: $STORAGE_THEMES
---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  labels:
    app: postgres
  name: $PREFIX-postgres
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
  name: $PREFIX-postgres
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
  name: $PREFIX-service
  namespace: $NAMESPACE
spec:
  type: NodePort
  ports:
  - name: http
    port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: $PREFIX
---
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  labels:
    app: $PREFIX
  name: $PREFIX-deployment
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $PREFIX
  template:
    metadata:
      labels:
        app: $PREFIX
    spec:
      containers:
      - image: $KEYCLOAK_IMAGE
        name: $PREFIX
        ports:
        - containerPort: 8080
          protocol: TCP
        volumeMounts:
        - mountPath: "/opt/jboss/keycloak/themes/mykrobe"
          name: $PREFIX-theme-volume
        env:
        - name: DB_VENDOR
          value: POSTGRES
        - name: DB_ADDR
          value: $DB_ADDR
        - name: DB_DATABASE
          value: $PREFIX
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
      - name: $PREFIX-theme-volume
        persistentVolumeClaim:
          claimName: $PREFIX-theme-data
      imagePullSecrets:
      - name: dockerhub
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: atlas-$PREFIX-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
  namespace: $NAMESPACE
spec:
  backend:
    serviceName: $PREFIX-service
    servicePort: 8080
  tls:
  - hosts:
    - $HOST
    secretName: $PREFIX-mykro-be-tls
  rules:
  - host: $HOST
    http:
      paths:
      - backend:
          serviceName: $PREFIX-service
          servicePort: 8080
EOF