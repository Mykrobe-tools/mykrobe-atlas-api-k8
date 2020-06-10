#!/bin/bash

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: distance-api-sa
  namespace: $NAMESPACE
---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: mykrobe-atlas-distance-deployment
  labels:
    app: mykrobe-atlas-distance
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: mykrobe-atlas-distance
  template:
    metadata:
      labels:
        app: mykrobe-atlas-distance
    spec:
      serviceAccountName: distance-api-sa
      volumes:
      - name: mykrobe-atlas-distance-data
        persistentVolumeClaim:
          claimName: mykrobe-atlas-distance-data
      containers:
      - name: mykrobe-atlas-distance
        image: $DISTANCE_API_IMAGE
        ports:
        - containerPort: 8080
        volumeMounts:
        - mountPath: "/data/databases"
          name: mykrobe-atlas-distance-data
      resources:
        limits:
          memory: $LIMIT_MEMORY_DISTANCE
          cpu: $LIMIT_CPU_DISTANCE
        requests:
          memory: $REQUEST_MEMORY_DISTANCE
          cpu: $REQUEST_CPU_DISTANCE
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mykrobe-atlas-distance-data
  namespace: $NAMESPACE
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: mykrobe-atlas-distance-service
  labels:
    app: mykrobe-atlas-distance
  namespace: $NAMESPACE
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: mykrobe-atlas-distance
EOF