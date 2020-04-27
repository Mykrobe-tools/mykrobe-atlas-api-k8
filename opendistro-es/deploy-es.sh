#!/bin/bash

source config.sh

echo ""
echo "Deploying OpenDistro using:"
echo " - Image: $OPENDISTRO_IMAGE"
echo " - Namespace: $NAMESPACE"
echo ""

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: mykrobe-opendistro-es
    release: mykrobe
  name: mykrobe-opendistro-es-es
  namespace: $NAMESPACE
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: mykrobe-opendistro-es
    release: mykrobe
  name: mykrobe-opendistro-es-kibana
  namespace: $NAMESPACE
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  labels:
    app: mykrobe-opendistro-es
    release: mykrobe
  name: mykrobe-opendistro-es-es
  namespace: $NAMESPACE
rules:
- apiGroups:
  - extensions
  resourceNames:
  - mykrobe-opendistro-es-psp
  resources:
  - podsecuritypolicies
  verbs:
  - use
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  labels:
    app: mykrobe-opendistro-es
    release: mykrobe
  name: mykrobe-opendistro-es-kibana
  namespace: $NAMESPACE
rules:
- apiGroups:
  - extensions
  resourceNames:
  - mykrobe-opendistro-es-psp
  resources:
  - podsecuritypolicies
  verbs:
  - use
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    app: mykrobe-opendistro-es
    release: mykrobe
  name: mykrobe-opendistro-es-elastic-rolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: mykrobe-opendistro-es-es
subjects:
- kind: ServiceAccount
  name: mykrobe-opendistro-es-es
  namespace: $NAMESPACE
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    app: mykrobe-opendistro-es
    release: mykrobe
  name: mykrobe-opendistro-es-kibana-rolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: mykrobe-opendistro-es-kibana
subjects:
- kind: ServiceAccount
  name: mykrobe-opendistro-es-kibana
  namespace: $NAMESPACE
---
apiVersion: v1
data:
  logging.yml: YXBwZW5kZXI6CiAgY29uc29sZToKICAgIGxheW91dDoKICAgICAgY29udmVyc2lvblBhdHRlcm46ICdbJWR7SVNPODYwMX1dWyUtNXBdWyUtMjVjXSAlbSVuJwogICAgICB0eXBlOiBjb25zb2xlUGF0dGVybgogICAgdHlwZTogY29uc29sZQplcy5sb2dnZXIubGV2ZWw6IElORk8KbG9nZ2VyOgogIGFjdGlvbjogREVCVUcKICBjb20uYW1hem9uYXdzOiBXQVJOCnJvb3RMb2dnZXI6ICR7ZXMubG9nZ2VyLmxldmVsfSwgY29uc29sZQo=
kind: Secret
metadata:
  labels:
    app: mykrobe-opendistro-es
    release: mykrobe
  name: mykrobe-opendistro-es-es-config
  namespace: $NAMESPACE
type: Opaque
---
apiVersion: v1
kind: Service
metadata:
  annotations: {}
  labels:
    app: mykrobe-opendistro-es
    release: mykrobe
    role: client
  name: mykrobe-opendistro-es-client-service
  namespace: $NAMESPACE
spec:
  ports:
  - name: http
    port: 9200
  - name: transport
    port: 9300
  - name: metrics
    port: 9600
  selector:
    role: client
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: mykrobe-opendistro-es
    release: mykrobe
    role: data
  name: mykrobe-opendistro-es-data-svc
  namespace: $NAMESPACE
spec:
  clusterIP: None
  ports:
  - name: transport
    port: 9300
  - name: http
    port: 9200
  - name: metrics
    port: 9600
  selector:
    role: data
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: mykrobe-opendistro-es
    release: mykrobe
    role: master
  name: mykrobe-opendistro-es-discovery
  namespace: $NAMESPACE
spec:
  clusterIP: None
  ports:
  - port: 9300
    protocol: TCP
  selector:
    role: master
---
apiVersion: v1
kind: Service
metadata:
  annotations: {}
  labels:
    app: mykrobe-opendistro-es
    release: mykrobe
    role: kibana
  name: mykrobe-opendistro-es-kibana-svc
spec:
  ports:
  - name: kibana-svc
    port: 443
    targetPort: 5601
  selector:
    role: kibana
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: mykrobe-opendistro-es
    release: mykrobe
    role: client
  name: mykrobe-opendistro-es-client
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mykrobe-opendistro-es
      release: mykrobe
      role: client
  template:
    metadata:
      annotations: null
      labels:
        app: mykrobe-opendistro-es
        release: mykrobe
        role: client
    spec:
      containers:
      - env:
        - name: cluster.name
          value: elasticsearch
        - name: node.master
          value: "false"
        - name: node.ingest
          value: "true"
        - name: node.data
          value: "false"
        - name: network.host
          value: 0.0.0.0
        - name: node.name
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: discovery.seed_hosts
          value: mykrobe-opendistro-es-discovery
        - name: KUBERNETES_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: PROCESSORS
          valueFrom:
            resourceFieldRef:
              resource: limits.cpu
        - name: ES_JAVA_OPTS
          value: -Xms512m -Xmx512m
        image: $OPENDISTRO_IMAGE
        imagePullPolicy: Always
        livenessProbe:
          initialDelaySeconds: 60
          periodSeconds: 10
          tcpSocket:
            port: transport
        name: elasticsearch
        ports:
        - containerPort: 9200
          name: http
        - containerPort: 9300
          name: transport
        - containerPort: 9600
          name: metrics
        resources: {}
        volumeMounts:
        - mountPath: /usr/share/elasticsearch/config/logging.yml
          name: config
          subPath: logging.yml
      initContainers:
      - command:
        - sysctl
        - -w
        - vm.max_map_count=262144
        image: busybox:1.27.2
        name: init-sysctl
        securityContext:
          privileged: true
      serviceAccountName: mykrobe-opendistro-es-es
      volumes:
      - name: config
        secret:
          secretName: mykrobe-opendistro-es-es-config
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: mykrobe-opendistro-es
    release: mykrobe
    role: kibana
  name: mykrobe-opendistro-es-kibana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mykrobe-opendistro-es
      release: mykrobe
      role: kibana
  template:
    metadata:
      annotations: null
      labels:
        app: mykrobe-opendistro-es
        release: mykrobe
        role: kibana
    spec:
      containers:
      - env:
        - name: CLUSTER_NAME
          value: elasticsearch
        - name: ELASTICSEARCH_HOSTS
          value: https://mykrobe-opendistro-es-client-service:9200
        image: $OPENDISTRO_IMAGE
        name: mykrobe-opendistro-es-kibana
        ports:
        - containerPort: 5601
        resources: {}
        volumeMounts: null
      restartPolicy: Always
      serviceAccountName: mykrobe-opendistro-es-kibana
      volumes: null
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    app: mykrobe-opendistro-es
    release: mykrobe
    role: data
  name: mykrobe-opendistro-es-data
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mykrobe-opendistro-es
      release: mykrobe
      role: data
  serviceName: mykrobe-opendistro-es-data-svc
  template:
    metadata:
      annotations: null
      labels:
        app: mykrobe-opendistro-es
        release: mykrobe
        role: data
    spec:
      containers:
      - env:
        - name: cluster.name
          value: elasticsearch
        - name: node.master
          value: "false"
        - name: node.ingest
          value: "false"
        - name: network.host
          value: 0.0.0.0
        - name: node.name
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: discovery.seed_hosts
          value: mykrobe-opendistro-es-discovery
        - name: KUBERNETES_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: node.data
          value: "true"
        - name: PROCESSORS
          valueFrom:
            resourceFieldRef:
              resource: limits.cpu
        - name: ES_JAVA_OPTS
          value: -Xms512m -Xmx512m
        image: amazon/opendistro-for-elasticsearch:1.6.0
        imagePullPolicy: Always
        livenessProbe:
          initialDelaySeconds: 60
          periodSeconds: 10
          tcpSocket:
            port: transport
        name: elasticsearch
        ports:
        - containerPort: 9300
          name: transport
        resources: {}
        volumeMounts:
        - mountPath: /usr/share/elasticsearch/data
          name: data
          subPath: null
        - mountPath: /usr/share/elasticsearch/config/logging.yml
          name: config
          subPath: logging.yml
      initContainers:
      - command:
        - sysctl
        - -w
        - vm.max_map_count=262144
        image: busybox:1.27.2
        name: init-sysctl
        securityContext:
          privileged: true
      - command:
        - sh
        - -c
        - chown -R 1000:1000 /usr/share/elasticsearch/data
        image: busybox:1.27.2
        name: fixmount
        volumeMounts:
        - mountPath: /usr/share/elasticsearch/data
          name: data
          subPath: null
      serviceAccountName: mykrobe-opendistro-es-es
      volumes:
      - name: config
        secret:
          secretName: mykrobe-opendistro-es-es-config
  updateStrategy:
    type: RollingUpdate
  volumeClaimTemplates:
  - metadata:
      annotations: null
      name: data
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 8Gi
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    app: mykrobe-opendistro-es
    release: mykrobe
    role: master
  name: mykrobe-opendistro-es-master
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mykrobe-opendistro-es
      release: mykrobe
      role: master
  serviceName: mykrobe-opendistro-es-discovery
  template:
    metadata:
      annotations: null
      labels:
        app: mykrobe-opendistro-es
        release: mykrobe
        role: master
    spec:
      containers:
      - env:
        - name: cluster.name
          value: elasticsearch
        - name: cluster.initial_master_nodes
          value: mykrobe-opendistro-es-master-0,
        - name: node.master
          value: "true"
        - name: node.ingest
          value: "false"
        - name: node.data
          value: "false"
        - name: network.host
          value: 0.0.0.0
        - name: node.name
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: discovery.seed_hosts
          value: mykrobe-opendistro-es-discovery
        - name: KUBERNETES_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: PROCESSORS
          valueFrom:
            resourceFieldRef:
              resource: limits.cpu
        - name: ES_JAVA_OPTS
          value: -Xms512m -Xmx512m
        image: amazon/opendistro-for-elasticsearch:1.6.0
        imagePullPolicy: Always
        livenessProbe:
          initialDelaySeconds: 60
          periodSeconds: 10
          tcpSocket:
            port: transport
        name: elasticsearch
        ports:
        - containerPort: 9300
          name: transport
        - containerPort: 9200
          name: http
        - containerPort: 9600
          name: metrics
        resources: {}
        volumeMounts:
        - mountPath: /usr/share/elasticsearch/data
          name: data
          subPath: null
        - mountPath: /usr/share/elasticsearch/config/logging.yml
          name: config
          subPath: logging.yml
      initContainers:
      - command:
        - sysctl
        - -w
        - vm.max_map_count=262144
        image: busybox:1.27.2
        name: init-sysctl
        securityContext:
          privileged: true
      - command:
        - sh
        - -c
        - chown -R 1000:1000 /usr/share/elasticsearch/data
        image: busybox:1.27.2
        name: fixmount
        volumeMounts:
        - mountPath: /usr/share/elasticsearch/data
          name: data
          subPath: null
      serviceAccountName: mykrobe-opendistro-es-es
      volumes:
      - name: config
        secret:
          secretName: mykrobe-opendistro-es-es-config
  updateStrategy:
    type: RollingUpdate
  volumeClaimTemplates:
  - metadata:
      annotations: null
      name: data
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 8Gi
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  labels:
    app: mykrobe-opendistro-es
    release: mykrobe
  name: mykrobe-opendistro-es-psp
spec:
  fsGroup:
    ranges:
    - max: 65535
      min: 1
    rule: MustRunAs
  hostIPC: false
  hostNetwork: false
  hostPID: false
  privileged: true
  readOnlyRootFilesystem: false
  runAsUser:
    rule: RunAsAny
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    ranges:
    - max: 65535
      min: 1
    rule: MustRunAs
  volumes:
  - configMap
  - emptyDir
  - projected
  - secret
  - downwardAPI
  - persistentVolumeClaim
EOF