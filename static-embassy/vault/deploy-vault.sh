#!/bin/bash

cat <<EOF | kubectl apply -n $NAMESPACE -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $PREFIX-agent-injector-sa
  labels:
    app.kubernetes.io/name: $PREFIX-agent-injector
    app.kubernetes.io/instance: $PREFIX
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $PREFIX-sa
  labels:
    app.kubernetes.io/name: $PREFIX
    app.kubernetes.io/instance: $PREFIX
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: $PREFIX-agent-injector-clusterrole
  labels:
    app.kubernetes.io/name: $PREFIX-agent-injector
    app.kubernetes.io/instance: $PREFIX
rules:
- apiGroups: ["admissionregistration.k8s.io"]
  resources: ["mutatingwebhookconfigurations"]
  verbs: 
    - "get"
    - "list"
    - "watch"
    - "patch"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $PREFIX-agent-injector-binding
  labels:
    app.kubernetes.io/name: $PREFIX-agent-injector
    app.kubernetes.io/instance: $PREFIX
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: $PREFIX-agent-injector-clusterrole
subjects:
- kind: ServiceAccount
  name: $PREFIX-agent-injector-sa
  namespace: $NAMESPACE
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: $PREFIX-server-binding
  labels:
    app.kubernetes.io/name:  $PREFIX
    app.kubernetes.io/instance: $PREFIX
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: $PREFIX-sa
  namespace: $NAMESPACE
---
apiVersion: v1
kind: Service
metadata:
  name: $PREFIX-agent-injector-svc
  labels:
    app.kubernetes.io/name: $PREFIX-agent-injector
    app.kubernetes.io/instance: $PREFIX
spec:
  ports:
  - port: 443
    targetPort: 8080
  selector:
    app.kubernetes.io/name: $PREFIX-agent-injector
    app.kubernetes.io/instance: $PREFIX
    component: webhook
---
apiVersion: v1
kind: Service
metadata:
  name: $PREFIX-internal
  labels:
    app.kubernetes.io/name: $PREFIX
    app.kubernetes.io/instance: $PREFIX
  annotations:
    service.alpha.kubernetes.io/tolerate-unready-endpoints: "true"
spec:
  clusterIP: None
  publishNotReadyAddresses: true
  ports:
    - name: "http"
      port: 8200
      targetPort: 8200
    - name: https-internal
      port: 8201
      targetPort: 8201
  selector:
    app.kubernetes.io/name: $PREFIX
    app.kubernetes.io/instance: $PREFIX
    component: server
---
apiVersion: v1
kind: Service
metadata:
  name: $PREFIX
  labels:
    app.kubernetes.io/name: $PREFIX
    app.kubernetes.io/instance: $PREFIX
  annotations:
    # This must be set in addition to publishNotReadyAddresses due
    # to an open issue where it may not work:
    # https://github.com/kubernetes/kubernetes/issues/58662
    service.alpha.kubernetes.io/tolerate-unready-endpoints: "true"
spec:
  # We want the servers to become available even if they're not ready
  # since this DNS is also used for join operations.
  publishNotReadyAddresses: true
  ports:
    - name: http
      port: 8200
      targetPort: 8200
    - name: https-internal
      port: 8201
      targetPort: 8201
  selector:
    app.kubernetes.io/name: $PREFIX
    app.kubernetes.io/instance: $PREFIX
    component: server
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $PREFIX-agent-injector
  labels:
    app.kubernetes.io/name: $PREFIX-agent-injector
    app.kubernetes.io/instance: $PREFIX
    component: webhook
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: $PREFIX-agent-injector
      app.kubernetes.io/instance: $PREFIX
      component: webhook
  template:
    metadata:
      labels:
        app.kubernetes.io/name: $PREFIX-agent-injector
        app.kubernetes.io/instance: $PREFIX
        component: webhook
    spec:
      serviceAccountName: "$PREFIX-agent-injector-sa"
      securityContext:
        runAsNonRoot: true
        runAsGroup: 1000
        runAsUser: 100
      containers:
        - name: sidecar-injector
          image: "hashicorp/vault-k8s:0.3.0"
          imagePullPolicy: "IfNotPresent"
          env:
            - name: AGENT_INJECT_LISTEN
              value: ":8080"
            - name: AGENT_INJECT_LOG_LEVEL
              value: info
            - name: AGENT_INJECT_VAULT_ADDR
              value: http://$PREFIX.$NAMESPACE.svc:8200
            - name: AGENT_INJECT_VAULT_AUTH_PATH
              value: auth/kubernetes
            - name: AGENT_INJECT_VAULT_IMAGE
              value: "vault:1.4.0"
            - name: AGENT_INJECT_TLS_AUTO
              value: $PREFIX-agent-injector-cfg
            - name: AGENT_INJECT_TLS_AUTO_HOSTS
              value: $PREFIX-agent-injector-svc,$PREFIX-agent-injector-svc.$NAMESPACE,$PREFIX-agent-injector-svc.$NAMESPACE.svc
            - name: AGENT_INJECT_LOG_FORMAT
              value: standard
            - name: AGENT_INJECT_REVOKE_ON_SHUTDOWN
              value: "false"
          args:
            - agent-inject
            - 2>&1
          livenessProbe:
            httpGet:
              path: /health/ready
              port: 8080
              scheme: HTTPS
            failureThreshold: 2
            initialDelaySeconds: 1
            periodSeconds: 2
            successThreshold: 1
            timeoutSeconds: 5
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 8080
              scheme: HTTPS
            failureThreshold: 2
            initialDelaySeconds: 2
            periodSeconds: 2
            successThreshold: 1
            timeoutSeconds: 5
---
apiVersion: admissionregistration.k8s.io/v1beta1
kind: MutatingWebhookConfiguration
metadata:
  name: $PREFIX-agent-injector-cfg
  labels:
    app.kubernetes.io/name: agent-injector
    app.kubernetes.io/instance: $PREFIX
webhooks:
  - name: vault.hashicorp.com
    clientConfig:
      service:
        name: $PREFIX-agent-injector-svc
        path: "/mutate"
        namespace: $NAMESPACE
      caBundle: 
    rules:
      - operations: ["CREATE", "UPDATE"]
        apiGroups: [""]
        apiVersions: ["v1"]
        resources: ["pods"]
EOF

sed "s#{NAMESPACE}#$NAMESPACE#g" deploy.yaml > deploy-tmp0.yaml
sed "s#{PREFIX}#$PREFIX#g" deploy-tmp0.yaml > deploy-tmp1.yaml
sed "s#{REQUEST_MEMORY}#$REQUEST_MEMORY#g" deploy-tmp1.yaml > deploy-tmp2.yaml
sed "s#{REQUEST_CPU}#$REQUEST_CPU#g" deploy-tmp2.yaml > deploy-tmp3.yaml
sed "s#{LIMIT_MEMORY}#$LIMIT_MEMORY#g" deploy-tmp3.yaml > deploy-tmp4.yaml
sed "s#{LIMIT_CPU}#$LIMIT_CPU#g" deploy-tmp4.yaml> deploy-tmp5.yaml
sed "s#{EPHERMERAL_STORAGE}#$EPHERMERAL_STORAGE#g" deploy-tmp5.yaml > deploy-tmp6.yaml
sed "s#{REQUEST_STORAGE}#$REQUEST_STORAGE#g" deploy-tmp6.yaml > deploy-tmp7.yaml
sed "s#{IMAGE_NAME}#$IMAGE_NAME#g" deploy-tmp7.yaml > deploy-tmp8.yaml
sed "s#{LIMIT_STORAGE}#$LIMIT_STORAGE#g" deploy-tmp8.yaml > deploy-resolved.yaml

kubectl apply -f deploy-resolved.yaml -n $NAMESPACE

rm deploy-*.yaml