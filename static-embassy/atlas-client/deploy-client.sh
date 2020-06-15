#!/bin/bash

echo ""
echo "Deploying atlas client using:"
echo " - Namespace: $NAMESPACE"
echo " - Prefix: $PREFIX"
echo " - Client Image: $CLIENT_IMAGE"
echo " - Host: $HOST"
echo ""

echo "Limits:"
echo " - Request CPU: $REQUEST_CPU"
echo " - Request Memory: $REQUEST_MEMORY"
echo " - Request Storage: $REQUEST_STORAGE"
echo " - Limit CPU: $LIMIT_CPU"
echo " - Limit Memory: $LIMIT_MEMORY"
echo " - Limit Storage: $LIMIT_STORAGE"
echo ""

echo "Env:"
echo " - Keycloak URL: $REACT_APP_KEYCLOAK_URL"
echo " - Keycloak Realm: $REACT_APP_KEYCLOAK_REALM"
echo " - Keycloak Client: $REACT_APP_KEYCLOAK_CLIENT_ID"
echo " - API URL: $REACT_APP_API_URL"
echo " - API URL Swagger Docs: $REACT_APP_API_SPEC_URL"
echo " - App Storage Key (Cookie): $REACT_APP_TOKEN_STORAGE_KEY"
echo ""

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: $PREFIX
  name: $PREFIX-sa
  namespace: $NAMESPACE
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
kind: Secret
metadata:
  name: $PREFIX-env-secret
  namespace: $NAMESPACE
data:
  REACT_APP_TOKEN_STORAGE_KEY: $REACT_APP_TOKEN_STORAGE_KEY
  REACT_APP_GOOGLE_MAPS_API_KEY: $REACT_APP_GOOGLE_MAPS_API_KEY
  REACT_APP_BOX_CLIENT_ID: $REACT_APP_BOX_CLIENT_ID
  REACT_APP_DROPBOX_APP_KEY: $REACT_APP_DROPBOX_APP_KEY
  REACT_APP_GOOGLE_DRIVE_CLIENT_ID: $REACT_APP_GOOGLE_DRIVE_CLIENT_ID
  REACT_APP_GOOGLE_DRIVE_DEVELOPER_KEY: $REACT_APP_GOOGLE_DRIVE_DEVELOPER_KEY
  REACT_APP_ONEDRIVE_CLIENT_ID: $REACT_APP_ONEDRIVE_CLIENT_ID
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
      serviceAccountName: $PREFIX-sa
      containers:
      - image: $CLIENT_IMAGE
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
        - mountPath: "/home/node/data/forever"
          subPath: "forever"
          name: $PREFIX-app-data
          readOnly: false 
        - mountPath: "/home/node/data/logs"
          subPath: "logs"
          name: $PREFIX-app-data
          readOnly: false 
        env:
        - name: HOST
          value: 0.0.0.0
        - name: NODE_OPTIONS
          value: '--max-old-space-size=$NODE_OPTIONS_MEMORY'
        - name: REACT_APP_API_URL
          value: $REACT_APP_API_URL
        - name: REACT_APP_API_SPEC_URL
          value: $REACT_APP_API_SPEC_URL
        - name: REACT_APP_KEYCLOAK_URL
          value: $REACT_APP_KEYCLOAK_URL
        - name: REACT_APP_KEYCLOAK_REALM
          value: $REACT_APP_KEYCLOAK_REALM
        - name: REACT_APP_KEYCLOAK_CLIENT_ID
          value: $REACT_APP_KEYCLOAK_CLIENT_ID
        - name: REACT_APP_KEYCLOAK_IDP
          value: $REACT_APP_KEYCLOAK_IDP
        - name: REACT_APP_TOKEN_STORAGE_KEY
          valueFrom:
            secretKeyRef:
              name: $PREFIX-env-secret
              key: REACT_APP_TOKEN_STORAGE_KEY
          value: $REACT_APP_TOKEN_STORAGE_KEY
        - name: REACT_APP_GOOGLE_MAPS_API_KEY
          valueFrom:
            secretKeyRef:
              name: $PREFIX-env-secret
              key: REACT_APP_GOOGLE_MAPS_API_KEY
        - name: REACT_APP_BOX_CLIENT_ID
          valueFrom:
            secretKeyRef:
              name: $PREFIX-env-secret
              key: REACT_APP_BOX_CLIENT_ID
        - name: REACT_APP_DROPBOX_APP_KEY
          valueFrom:
            secretKeyRef:
              name: $PREFIX-env-secret
              key: REACT_APP_DROPBOX_APP_KEY
        - name: REACT_APP_GOOGLE_DRIVE_CLIENT_ID
          valueFrom:
            secretKeyRef:
              name: $PREFIX-env-secret
              key: REACT_APP_GOOGLE_DRIVE_CLIENT_ID
        - name: REACT_APP_GOOGLE_DRIVE_DEVELOPER_KEY
          valueFrom:
            secretKeyRef:
              name: $PREFIX-env-secret
              key: REACT_APP_GOOGLE_DRIVE_DEVELOPER_KEY
        - name: REACT_APP_ONEDRIVE_CLIENT_ID
          valueFrom:
            secretKeyRef:
              name: $PREFIX-env-secret
              key: REACT_APP_ONEDRIVE_CLIENT_ID
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
      - name: $PREFIX-app-data
        persistentVolumeClaim:
          claimName: $PREFIX-app-data
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
  namespace: $NAMESPACE
spec:
  backend:
    serviceName: $PREFIX-service
    servicePort: 3000
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
          servicePort: 3000