#!/bin/bash

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: redis-sa
  namespace: $NAMESPACE
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-data
  namespace: $NAMESPACE
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 32Gi
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-conf
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
    rename-command SREM ""
    rename-command RENAME ""
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: $NAMESPACE
spec:
  type: NodePort
  ports:
  - name: redis
    port: 6379
  selector:
    app: redis
---
apiVersion: apps/v1beta2
kind: StatefulSet
metadata:
  name: redis
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: redis
  serviceName: redis
  replicas: 1
  template:
    metadata:
      labels:
        app: redis
    spec:
      serviceAccountName: redis-sa
      securityContext:
        runAsUser: 9999
        runAsGroup: 9999
        fsGroup: 9999
        runAsNonRoot: true
      containers:
      - name: redis
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
      - name: redis-data
        persistentVolumeClaim:
          claimName: redis-data
      - name: redis-conf
        configMap:
          name: redis-conf
EOF
