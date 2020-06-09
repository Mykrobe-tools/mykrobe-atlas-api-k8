#!/bin/bash

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $ANALYSIS_PREFIX-sa
  namespace: $NAMESPACE
---
apiVersion: v1
data:
  ATLAS_API: $ATLAS_API
  BIGSI_URL: http://bigsi-aggregator-api-service/api/v1
  CELERY_BROKER_URL: redis://$REDIS_PREFIX:6379
  DEFAULT_OUTDIR: /data/out/
  FLASK_DEBUG: "1"
  REDIS_HOST: $REDIS_PREFIX
  REDIS_PORT: "6379"
  TB_GENBANK_PATH: /config/NC_000962.3.gb
  TB_REFERENCE_PATH: /config/NC_000962.3.fasta
  TB_TREE_PATH_V1: /config/tb_tree.txt
kind: ConfigMap
metadata:
  name: $ANALYSIS_PREFIX-env
  namespace: $NAMESPACE
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $ANALYSIS_PREFIX-config-data
  namespace: $NAMESPACE
spec:
  storageClassName: nfs-client
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 200Mi
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: $ANALYSIS_PREFIX
  name: $ANALYSIS_PREFIX
  namespace: $NAMESPACE
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: $ANALYSIS_PREFIX
  type: NodePort
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: $ANALYSIS_PREFIX-worker
  name: $ANALYSIS_PREFIX-worker
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: $ANALYSIS_PREFIX-worker
  template:
    metadata:
      labels:
        app: $ANALYSIS_PREFIX-worker
    spec:
      serviceAccountName: $ANALYSIS_PREFIX-sa
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
            name: $ANALYSIS_PREFIX-env
        image: $ANALYSIS_API_IMAGE
        imagePullPolicy: IfNotPresent
        name: mykrobe-atlas-analysis
        volumeMounts:
        - mountPath: /data/
          name: uploads-data
        - mountPath: /config/
          name: $ANALYSIS_PREFIX-config-data
      volumes:
      - name: uploads-data
        persistentVolumeClaim:
          claimName: $ATLAS_API_PREFIX-uploads-data
      - name: $ANALYSIS_PREFIX-config-data
        persistentVolumeClaim:
          claimName: $ANALYSIS_PREFIX-config-data
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: $ANALYSIS_PREFIX
  name: $ANALYSIS_PREFIX
  namespace: $NAMESPACE
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 2
  selector:
    matchLabels:
      app: $ANALYSIS_PREFIX
  template:
    metadata:
      labels:
        app: $ANALYSIS_PREFIX
    spec:
      serviceAccountName: $ANALYSIS_PREFIX-sa
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
            name: $ANALYSIS_PREFIX-env
        image: $ANALYSIS_API_IMAGE
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
          claimName: $ATLAS_API_PREFIX-uploads-data
EOF