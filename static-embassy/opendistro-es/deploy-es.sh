#!/bin/bash

source config.sh

echo ""
echo "Deploying OpenDistro using:"
echo " - Application name: $APPLICATION_NAME"
echo " - Release name: $RELEASE_NAME"
echo " - ES Image: $OPENDISTRO_IMAGE"
echo " - KIBANA Image: $KIBANA_IMAGE"
echo " - Namespace: $NAMESPACE"
echo ""

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: $APPLICATION_NAME
    release: $RELEASE_NAME
  name: $APPLICATION_NAME-es
  namespace: $NAMESPACE
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: $APPLICATION_NAME
    release: $RELEASE_NAME
  name: $APPLICATION_NAME-kibana
  namespace: $NAMESPACE
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  labels:
    app: $APPLICATION_NAME
    release: $RELEASE_NAME
  name: $APPLICATION_NAME-es
  namespace: $NAMESPACE
rules:
- apiGroups:
  - extensions
  resourceNames:
  - $APPLICATION_NAME-psp
  resources:
  - podsecuritypolicies
  verbs:
  - use
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  labels:
    app: $APPLICATION_NAME
    release: $RELEASE_NAME
  name: $APPLICATION_NAME-kibana
  namespace: $NAMESPACE
rules:
- apiGroups:
  - extensions
  resourceNames:
  - $APPLICATION_NAME-psp
  resources:
  - podsecuritypolicies
  verbs:
  - use
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    app: $APPLICATION_NAME
    release: $RELEASE_NAME
  name: $APPLICATION_NAME-elastic-rolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $APPLICATION_NAME-es
subjects:
- kind: ServiceAccount
  name: $APPLICATION_NAME-es
  namespace: $NAMESPACE
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    app: $APPLICATION_NAME
    release: $RELEASE_NAME
  name: $APPLICATION_NAME-kibana-rolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: $APPLICATION_NAME-kibana
subjects:
- kind: ServiceAccount
  name: $APPLICATION_NAME-kibana
  namespace: $NAMESPACE
---
apiVersion: v1
data:
  logging.yml: YXBwZW5kZXI6CiAgY29uc29sZToKICAgIGxheW91dDoKICAgICAgY29udmVyc2lvblBhdHRlcm46ICdbJWR7SVNPODYwMX1dWyUtNXBdWyUtMjVjXSAlbSVuJwogICAgICB0eXBlOiBjb25zb2xlUGF0dGVybgogICAgdHlwZTogY29uc29sZQplcy5sb2dnZXIubGV2ZWw6IElORk8KbG9nZ2VyOgogIGFjdGlvbjogREVCVUcKICBjb20uYW1hem9uYXdzOiBXQVJOCnJvb3RMb2dnZXI6ICR7ZXMubG9nZ2VyLmxldmVsfSwgY29uc29sZQo=
kind: Secret
metadata:
  labels:
    app: $APPLICATION_NAME
    release: $RELEASE_NAME
  name: $APPLICATION_NAME-es-config
  namespace: $NAMESPACE
type: Opaque
---
apiVersion: v1
kind: Service
metadata:
  annotations: {}
  labels:
    app: $APPLICATION_NAME
    release: $RELEASE_NAME
    role: client
  name: $APPLICATION_NAME-client-service
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
    app: $APPLICATION_NAME
    release: $RELEASE_NAME
    role: data
  name: $APPLICATION_NAME-data-svc
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
    app: $APPLICATION_NAME
    release: $RELEASE_NAME
    role: master
  name: $APPLICATION_NAME-discovery
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
    app: $APPLICATION_NAME
    release: $RELEASE_NAME
    role: kibana
  name: $APPLICATION_NAME-kibana-svc
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
    app: $APPLICATION_NAME
    release: $RELEASE_NAME
    role: client
  name: $APPLICATION_NAME-client
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $APPLICATION_NAME
      release: $RELEASE_NAME
      role: client
  template:
    metadata:
      annotations: null
      labels:
        app: $APPLICATION_NAME
        release: $RELEASE_NAME
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
          value: $APPLICATION_NAME-discovery
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
      serviceAccountName: $APPLICATION_NAME-es
      volumes:
      - name: config
        secret:
          secretName: $APPLICATION_NAME-es-config
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: $APPLICATION_NAME
    release: $RELEASE_NAME
    role: kibana
  name: $APPLICATION_NAME-kibana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $APPLICATION_NAME
      release: $RELEASE_NAME
      role: kibana
  template:
    metadata:
      annotations: null
      labels:
        app: $APPLICATION_NAME
        release: $RELEASE_NAME
        role: kibana
    spec:
      containers:
      - env:
        - name: CLUSTER_NAME
          value: elasticsearch
        - name: ELASTICSEARCH_HOSTS
          value: https://$APPLICATION_NAME-client-service:9200
        image: $KIBANA_IMAGE
        name: $APPLICATION_NAME-kibana
        ports:
        - containerPort: 5601
        resources: {}
        volumeMounts: null
      restartPolicy: Always
      serviceAccountName: $APPLICATION_NAME-kibana
      volumes: null
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    app: $APPLICATION_NAME
    release: $RELEASE_NAME
    role: data
  name: $APPLICATION_NAME-data
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $APPLICATION_NAME
      release: $RELEASE_NAME
      role: data
  serviceName: $APPLICATION_NAME-data-svc
  template:
    metadata:
      annotations: null
      labels:
        app: $APPLICATION_NAME
        release: $RELEASE_NAME
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
          value: $APPLICATION_NAME-discovery
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
        image: $OPENDISTRO_IMAGE
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
      serviceAccountName: $APPLICATION_NAME-es
      volumes:
      - name: config
        secret:
          secretName: $APPLICATION_NAME-es-config
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
    app: $APPLICATION_NAME
    release: $RELEASE_NAME
    role: master
  name: $APPLICATION_NAME-master
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $APPLICATION_NAME
      release: $RELEASE_NAME
      role: master
  serviceName: $APPLICATION_NAME-discovery
  template:
    metadata:
      annotations: null
      labels:
        app: $APPLICATION_NAME
        release: $RELEASE_NAME
        role: master
    spec:
      containers:
      - env:
        - name: cluster.name
          value: elasticsearch
        - name: cluster.initial_master_nodes
          value: $APPLICATION_NAME-master-0,
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
          value: $APPLICATION_NAME-discovery
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
      serviceAccountName: $APPLICATION_NAME-es
      volumes:
      - name: config
        secret:
          secretName: $APPLICATION_NAME-es-config
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
    app: $APPLICATION_NAME
    release: $RELEASE_NAME
  name: $APPLICATION_NAME-psp
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