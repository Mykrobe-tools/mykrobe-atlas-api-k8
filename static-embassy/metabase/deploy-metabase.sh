#!/bin/bash

source config.sh

echo ""
echo "Deploying Mysql using:"
echo " - Namespace: $NAMESPACE"
echo " - Prefix: $PREFIX"
echo " - Metabase Image: $METABASE_IMAGE"
echo " - Database Name: $DATABASE"
echo " - Database User: $DB_USER"
echo " - User Password: $DB_PASSWORD"
echo " - DNS: $DNS"
echo " - APP_NAME: $APP_NAME"
echo ""

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Secret
metadata:
  name: $PREFIX-metabase-db
  namespace: $NAMESPACE
  labels:
    app: $PREFIX-metabase
type: Opaque
data:
  mysql-username: $DB_USER
  mysql-password: $DB_PASSWORD
---
apiVersion: v1
kind: Service
metadata:
  name: $PREFIX-$APP_NAME
  namespace: $NAMESPACE
  labels:
    app: $PREFIX-metabase
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 3000
      protocol: TCP
      name: metabase
  selector:
    app: $PREFIX-metabase
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: $PREFIX-$APP_NAME
  namespace: $NAMESPACE
  labels:
    app: $PREFIX-metabase
spec:
  selector:
    matchLabels:
      app: $PREFIX-metabase
  replicas: 1
  template:
    metadata:
      annotations:
        checksum/config: 9c0e3146fb43ee88bc5e667e4d75ab49cbcb63f5ec8454089df6efe0d362123e
      labels:
        app: $PREFIX-metabase
    spec:
      containers:
        - name: metabase
          image: $METABASE_IMAGE
          imagePullPolicy: IfNotPresent
          env:
          - name: MB_JETTY_HOST
            value: "0.0.0.0"
          - name: MB_JETTY_PORT
            value: "3000"
          - name: MB_DB_TYPE
            value: mysql
          - name: MB_DB_HOST
            value: "$PREFIX-mysql.$PREFIX-dev.svc.cluster.local"
          - name: MB_DB_PORT
            value: "3306"
          - name: MB_DB_DBNAME
            value: $DATABASE
          - name: MB_DB_USER
            valueFrom:
              secretKeyRef:
                name: $PREFIX-metabase-db
                key: mysql-username
          - name: MB_DB_PASS
            valueFrom:
              secretKeyRef:
                name: $PREFIX-metabase-db
                key: mysql-password
          - name: MB_PASSWORD_COMPLEXITY
            value: normal
          - name: MB_PASSWORD_LENGTH
            value: "6"
          - name: JAVA_TIMEZONE
            value: UTC
          - name: MB_EMOJI_IN_LOGS
            value: "true"
          ports:
            - containerPort: 3000
          livenessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 120
            timeoutSeconds: 30
            failureThreshold: 6
          readinessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 30
            timeoutSeconds: 3
            periodSeconds: 5
          resources:
            {}
            
      volumes:
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: $PREFIX-$APP_NAME
  namespace: $NAMESPACE
  labels:
    app: $PREFIX-metabase
  annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
      kubernetes.io/ingress.class: "nginx"
      nginx.ingress.kubernetes.io/cors-allow-origin: "*"
      nginx.ingress.kubernetes.io/enable-cors: "true"
      nginx.ingress.kubernetes.io/proxy-body-size: "10m"
spec:
  rules:
    - host: $DNS
      http:
        paths:
          - path: /
            backend:
              serviceName: $PREFIX-$APP_NAME
              servicePort: 80
  tls:
    - hosts:
      - $DNS
      secretName: $APP_NAME-$PREFIX-tls
EOF
