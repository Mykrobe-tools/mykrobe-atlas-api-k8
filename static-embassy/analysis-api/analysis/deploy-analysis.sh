#!/bin/bash

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: analysis-api-sa
  namespace: $NAMESPACE
---
apiVersion: v1
data:
  ATLAS_API: $ATLAS_API
  BIGSI_URL: http://mykrobe-atlas-bigsi-aggregator-api-service/api/v1
  CELERY_BROKER_URL: redis://redis:6379
  DEFAULT_OUTDIR: /data/out/
  FLASK_DEBUG: "1"
  REDIS_HOST: redis
  REDIS_PORT: "6379"
  TB_GENBANK_PATH: data/NC_000962.3.gb
  TB_REFERENCE_PATH: data/NC_000962.3.fasta
  TB_TREE_PATH_V1: data/tb_newick.txt
kind: ConfigMap
metadata:
  name: atlas-analysis-api-env
  namespace: $NAMESPACE
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: mykrobe-atlas-analysis-api
  name: mykrobe-atlas-analysis-api
  namespace: $NAMESPACE
spec:
  ports:
  - nodePort: 30412
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: mykrobe-atlas-analysis-api
  type: NodePort
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: mykrobe-atlas-analysis-worker
  name: mykrobe-atlas-analysis-worker
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: mykrobe-atlas-analysis-worker
  template:
    metadata:
      labels:
        app: mykrobe-atlas-analysis-worker
    spec:
      serviceAccountName: analysis-api-sa
      containers:
      - args:
        - -A
        - app.celery
        - worker
        - -O
        - fair
        - -l
        - debug
        - --concurrency=1
        command:
        - celery
        env:
        - name: CONFIG_HASH_MD5
          value: $ANALYSIS_CONFIG_HASH_MD5
        envFrom:
        - configMapRef:
            name: atlas-analysis-api-env
        image: $ANALYSIS_API_IMAGE
        imagePullPolicy: IfNotPresent
        name: mykrobe-atlas-analysis
        volumeMounts:
        - mountPath: /data/
          name: uploads-data
      volumes:
      - name: uploads-data
        persistentVolumeClaim:
          claimName: uploads-data
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: mykrobe-atlas-analysis-api
  name: mykrobe-atlas-analysis-api
  namespace: $NAMESPACE
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 2
  selector:
    matchLabels:
      app: mykrobe-atlas-analysis-api
  template:
    metadata:
      labels:
        app: mykrobe-atlas-analysis-api
    spec:
      serviceAccountName: analysis-api-sa
      containers:
      - args:
        - -c
        - uwsgi --http :80  --harakiri 300  --buffer-size=65535  -w wsgi:app
        command:
        - /bin/sh
        env:
        - name: CONFIG_HASH_MD5
          value: $ANALYSIS_CONFIG_HASH_MD5
        envFrom:
        - configMapRef:
            name: atlas-analysis-api-env
        image: ANALYSIS_API_IMAGE
        imagePullPolicy: IfNotPresent
        name: mykrobe-atlas-analysis
        ports:
        - containerPort: 80
          protocol: TCP
        volumeMounts:
        - mountPath: /data/
          name: uploads-data
        resources:
          limits:
            memory: $LIMIT_MEMORY_ANALYSIS
            cpu: $LIMIT_CPU_ANALYSIS
          requests:
            memory: $REQUEST_MEMORY_ANALYSIS
            cpu: $REQUEST_CPU_ANALYSIS
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      volumes:
      - name: uploads-data
        persistentVolumeClaim:
          claimName: uploads-data
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    kubernetes.io/ingress.class: nginx
  name: analysis-ingress
  namespace: $NAMESPACE
spec:
  backend:
    serviceName: mykrobe-atlas-analysis-api
    servicePort: 80
  rules:
  - host: $ANALYSIS_API_DNS
    http:
      paths:
      - backend:
          serviceName: mykrobe-atlas-analysis-api
          servicePort: 80
  tls:
  - hosts:
    - $ANALYSIS_API_DNS
    secretName: analysis-$TARGET_ENV-mykro-be-tls
EOF