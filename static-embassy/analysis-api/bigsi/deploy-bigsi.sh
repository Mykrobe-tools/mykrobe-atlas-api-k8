#!/bin/bash

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $BIGSI_PREFIX-sa
  namespace: $NAMESPACE
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: bigsi-aggregator-api
    tier: front
  name: bigsi-aggregator-api-deployment
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: bigsi-aggregator-api
  template:
    metadata:
      labels:
        app: bigsi-aggregator-api
    spec:
      serviceAccountName: $BIGSI_PREFIX-sa
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
        name: bigsi-aggregator
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
    app: bigsi-aggregator-api
  name: bigsi-aggregator-api-service
  namespace: $NAMESPACE
spec:
  ports:
  - nodePort: 31290
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: bigsi-aggregator-api
  sessionAffinity: None
  type: NodePort
---
apiVersion: v1
data:
  ATLAS_API: $ATLAS_API
  BIGSI_URLS: http://bigsi-service
  REDIS_HOST: $REDIS_PREFIX
  REDIS_IP: $REDIS_PREFIX
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
    app: bigsi-aggregator-worker
    tier: front
  name: bigsi-aggregator-worker
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: bigsi-aggregator-worker
  template:
    metadata:
      labels:
        app: bigsi-aggregator-worker
    spec:
      serviceAccountName: $BIGSI_PREFIX-sa
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
        name: bigsi-aggregator-worker
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
  name: bigsi-config
  namespace: $NAMESPACE
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: $PREFIX_BIGSI
    tier: front
  name: bigsi-deployment
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: $PREFIX_BIGSI
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: $PREFIX_BIGSI
    spec:
      serviceAccountName: $BIGSI_PREFIX-sa
      containers:
      - args:
        - -c
        - uwsgi --enable-threads --http :80 --wsgi-file bigsi/__main__.py --callable
          __hug_wsgi__ --processes=4 --buffer-size=32768 --harakiri=300000
        command:
        - /bin/sh
        envFrom:
        - configMapRef:
            name: bigsi-env
        image: $BIGSI_IMAGE
        imagePullPolicy: IfNotPresent
        name: $PREFIX_BIGSI
        ports:
        - containerPort: 80
          protocol: TCP
        volumeMounts:
        - mountPath: /data/
          name: pv-storage-for-bigsi
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
      - name: pv-storage-for-bigsi
        persistentVolumeClaim:
          claimName: pv-claim-for-bigsi
      - configMap:
          defaultMode: 420
          name: bigsi-config
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
    serviceName: bigsi-aggregator-api-service
    servicePort: 80
  rules:
  - host: $BIGSI_DNS
    http:
      paths:
      - backend:
          serviceName: bigsi-aggregator-api-service
          servicePort: 80
  tls:
  - hosts:
    - $BIGSI_DNS
    secretName: $BIGSI_PREFIX-mykro-be-tls
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: bigsi-data
  namespace: $NAMESPACE
spec:
  storageClassName: nfs-client
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 8Gi
EOF