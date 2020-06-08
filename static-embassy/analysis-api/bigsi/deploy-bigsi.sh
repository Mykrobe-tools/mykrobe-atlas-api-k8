#!/bin/bash

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bigsi-api-sa
  namespace: $NAMESPACE
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: mykrobe-atlas-bigsi-aggregator-api
    tier: front
  name: mykrobe-atlas-bigsi-aggregator-api-deployment
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: mykrobe-atlas-bigsi-aggregator-api
  template:
    metadata:
      labels:
        app: mykrobe-atlas-bigsi-aggregator-api
    spec:
      serviceAccountName: bigsi-api-sa
      containers:
      - args:
        - -c
        - uwsgi --http :80  --harakiri 300  --buffer-size=65535  -w wsgi
        command:
        - /bin/sh
        env:
        - name: CONFIG_HASH_MD5
          value: $BIGSI_CONFIG_HASH_MD5
        envFrom:
        - configMapRef:
            name: bigsi-aggregator-env
        image: $BIGSI_AGGREGATOR_IMAGE
        imagePullPolicy: IfNotPresent
        name: mykrobe-atlas-bigsi-aggregator
        ports:
        - containerPort: 80
          protocol: TCP
      dnsPolicy: ClusterFirst
      restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: mykrobe-atlas-bigsi-aggregator-api
  name: mykrobe-atlas-bigsi-aggregator-api-service
  namespace: $NAMESPACE
spec:
  ports:
  - nodePort: 31290
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: mykrobe-atlas-bigsi-aggregator-api
  sessionAffinity: None
  type: NodePort
---
apiVersion: v1
data:
  ATLAS_API: $ATLAS_API
  BIGSI_URLS: http://mykrobe-atlas-bigsi-service
  REDIS_HOST: redis
  REDIS_IP: redis
  REDIS_PORT: "6379"
kind: ConfigMap
metadata:
  name: bigsi-aggregator-env
  namespace: $NAMESPACE
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: mykrobe-atlas-bigsi-aggregator-worker
    tier: front
  name: mykrobe-atlas-bigsi-aggregator-worker
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: mykrobe-atlas-bigsi-aggregator-worker
  template:
    metadata:
      labels:
        app: mykrobe-atlas-bigsi-aggregator-worker
    spec:
      serviceAccountName: bigsi-api-sa
      containers:
      - args:
        - -A
        - bigsi_aggregator.celery
        - worker
        - --concurrency=1
        command:
        - celery
        env:
        - name: CONFIG_HASH_MD5
          value: $BIGSI_CONFIG_HASH_MD5
        envFrom:
        - configMapRef:
            name: bigsi-aggregator-env
        image: $BIGSI_AGGREGATOR_IMAGE
        imagePullPolicy: IfNotPresent
        name: mykrobe-atlas-bigsi-aggregator-worker
      dnsPolicy: ClusterFirst
      restartPolicy: Always
---
apiVersion: v1
data:
  config.yaml: |-
    h: 1
    k: 31
    m: 28000000
    nproc: 1
    storage-engine: berkeleydb
    storage-config:
      filename: /data/test-bigsi-bdb
      flag: "c" ## Change to 'r' for read-only access
kind: ConfigMap
metadata:
  name: mykrobe-atlas-bigsi-config
  namespace: $NAMESPACE
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: mykrobe-atlas-bigsi
    tier: front
  name: mykrobe-atlas-bigsi-deployment
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: mykrobe-atlas-bigsi
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: mykrobe-atlas-bigsi
    spec:
      serviceAccountName: bigsi-api-sa
      containers:
      - args:
        - -c
        - uwsgi --enable-threads --http :80 --wsgi-file bigsi/__main__.py --callable
          __hug_wsgi__ --processes=4 --buffer-size=32768 --harakiri=300000
        command:
        - /bin/sh
        envFrom:
        - configMapRef:
            name: mykrobe-atlas-bigsi-env
        image: $BIGSI_IMAGE
        imagePullPolicy: IfNotPresent
        name: mykrobe-atlas-bigsi
        ports:
        - containerPort: 80
          protocol: TCP
        volumeMounts:
        - mountPath: /data/
          name: pv-storage-for-mykrobe-atlas-bigsi
        - mountPath: /etc/bigsi/conf/
          name: configmap-volume
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      resources:
        limits:
          memory: $LIMIT_MEMORY_BIGSI
          cpu: $LIMIT_CPU_BIGSI
        requests:
          memory: $REQUEST_MEMORY_BIGSI
          cpu: $REQUEST_CPU_BIGSI
      volumes:
      - name: pv-storage-for-mykrobe-atlas-bigsi
        persistentVolumeClaim:
          claimName: pv-claim-for-mykrobe-atlas-bigsi
      - configMap:
          defaultMode: 420
          name: mykrobe-atlas-bigsi-config
        name: configmap-volume
---
apiVersion: v1
data:
  BIGSI_CONFIG: /etc/bigsi/conf/config.yaml
kind: ConfigMap
metadata:
  name: bigsi-env
  namespace: $NAMESPACE
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    kubernetes.io/ingress.class: nginx
  name: bigsi-ingress
  namespace: $NAMESPACE
spec:
  backend:
    serviceName: mykrobe-atlas-bigsi-aggregator-api-service
    servicePort: 80
  rules:
  - host: $BIGSI_DNS
    http:
      paths:
      - backend:
          serviceName: mykrobe-atlas-bigsi-aggregator-api-service
          servicePort: 80
  tls:
  - hosts:
    - $BIGSI_DNS
    secretName: bigsi-$TARGET_ENV-mykro-be-tls
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: bigsi-data
  namespace: $NAMESPACE
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 8Gi
EOF