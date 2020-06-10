#!/bin/bash

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $REDIS_PREFIX-sa
  namespace: $NAMESPACE
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $REDIS_PREFIX-data
  namespace: $NAMESPACE
spec:
  storageClassName: nfs-client
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: $REDIS_PREFIX-conf
  namespace: $NAMESPACE
data:
  redis.conf: |
    rename-command FLUSHDB ""
    rename-command FLUSHALL ""
    rename-command DEBUG ""
    rename-command KEYS ""
    rename-command PEXPIRE ""
    rename-command CONFIG ""
    rename-command SHUTDOWN ""
    rename-command BGREWRITEAOF ""
    rename-command BGSAVE ""
    rename-command SAVE ""
    rename-command SPOP ""
    rename-command RENAME ""
---
apiVersion: apps/v1beta2
kind: StatefulSet
metadata:
  name: $REDIS_PREFIX
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: $REDIS_PREFIX
  serviceName: $REDIS_PREFIX
  replicas: 1
  template:
    metadata:
      labels:
        app: $REDIS_PREFIX
    spec:
      serviceAccountName: $REDIS_PREFIX-sa
      securityContext:
        runAsUser: 9999
        runAsGroup: 9999
        fsGroup: 9999
        runAsNonRoot: true
      containers:
      - name: $REDIS_PREFIX
        image: $REDIS_IMAGE
        imagePullPolicy: Always
        command:
        - redis-server
        - "/etc/redis/redis.conf"
        ports:
        - containerPort: 6379
          name: redis
        volumeMounts:
        - name: redis-data
          mountPath: "/data/"
        - name: redis-conf
          mountPath: /etc/redis
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
        resources:
          limits:
            memory: $POD_MEMORY_REDIS
            cpu: $POD_CPU_REDIS
          requests:
            memory: $POD_MEMORY_REDIS
            cpu: $POD_CPU_REDIS
      volumes:
      - name: $REDIS_PREFIX-data
        persistentVolumeClaim:
          claimName: $REDIS_PREFIX-data
      - name: $REDIS_PREFIX-conf
        configMap:
          name: $REDIS_PREFIX-conf
---
apiVersion: v1
kind: Service
metadata:
  name: $REDIS_PREFIX
  namespace: $NAMESPACE
spec:
  type: NodePort
  ports:
  - name: $REDIS_PREFIX
    port: 6379
  selector:
    app: $REDIS_PREFIX
EOF
