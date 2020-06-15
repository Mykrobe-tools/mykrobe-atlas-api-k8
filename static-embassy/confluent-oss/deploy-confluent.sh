#!/bin/bash

echo ""
echo "Deploying Confluent platform using:"
echo " - Namespace: $NAMESPACE"
echo " - Prefix: $PREFIX"
echo " - Confluent: $CONFLUENT"
echo " - Zookeeper: $ZOOKEEPER"
echo " - Schema Registry: $SCHEMA_REGISTRY"
echo " - Kafka Connect: $KAFKA_CONNECT"
echo " - Kafka: $KAFKA"
echo " - Control-center Image: $CONTROL_CENTER_IMAGE"
echo " - Kafka-connect Image: $KAFKA_CONNECT_IMAGE"
echo " - Schema-registry Image: $SCHEMA_REGISTRY_IMAGE"
echo " - Kafka broker Image: $KAFKA_BROKER_IMAGE"
echo " - Zookeeper Image: $ZOOKEEPER_IMAGE"
echo " - Broker NodePort: $BROKER_NODEPORT0"
echo ""


echo "Limits:"
echo " - Request Zookeeper CPU: $REQUEST_ZOOKEEPER_CPU"
echo " - Request Zookeeper Memory: $REQUEST_ZOOKEEPER_MEMORY"
echo " - Request Zookeeper Storage: $REQUEST_ZOOKEEPER_STORAGE"
echo " - Limit Zookeeper CPU: $LIMIT_ZOOKEEPER_CPU"
echo " - Limit Zookeeper Memory: $LIMIT_ZOOKEEPER_MEMORY"
echo " - Limit Zookeeper Storage: $LIMIT_ZOOKEEPER_STORAGE"
echo " - Zookeeper Ephermeral Storage: $ZOOKEEPER_EPHERMERAL_STORAGE"
echo " - Request Broker CPU: $REQUEST_KAFKA_CPU"
echo " - Request Broker Memory: $REQUEST_KAFKA_MEMORY"
echo " - Request Broker Storage: $REQUEST_KAFKA_STORAGE"
echo " - Limit Broker CPU: $LIMIT_KAFKA_CPU"
echo " - Limit Broker Memory: $LIMIT_KAFKA_MEMORY"
echo " - Limit Broker Storage: $LIMIT_KAFKA_STORAGE"
echo " - Request Schema Registry CPU: $REQUEST_SCHEMA_REGISTRY_CPU"
echo " - Request Schema Registry Memory: $REQUEST_SCHEMA_REGISTRY_MEMORY"
echo " - Limit Schema Registry CPU: $LIMIT_SCHEMA_REGISTRY_CPU"
echo " - Limit Schema Registry Memory: $LIMIT_SCHEMA_REGISTRY_MEMORY"
echo " - Request Connect CPU: $REQUEST_KAFKA_CONNECT_CPU"
echo " - Request Connect Memory: $REQUEST_KAFKA_CONNECT_MEMORY"
echo " - Limit Connect CPU: $LIMIT_KAFKA_CONNECT_CPU"
echo " - Limit Connect Memory: $LIMIT_KAFKA_CONNECT_MEMORY"
echo ""

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: $CONFLUENT
  name: $PREFIX-insight
  namespace: $NAMESPACE
---
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: $CONFLUENT-$ZOOKEEPER-pdb
  namespace: $NAMESPACE
  labels:
    app: $ZOOKEEPER
    release: $CONFLUENT
spec:
  selector:
    matchLabels:
      app: $ZOOKEEPER
      release: $CONFLUENT
  maxUnavailable: 1
---
apiVersion: v1
kind: Service
metadata:
  name: $CONFLUENT-cc
  namespace: $NAMESPACE
  labels:
    app: cc
    release: $CONFLUENT
spec:
  ports:
    - name: cc-http
      port: 9021
  selector:
    app: cc
    release: $CONFLUENT

---
apiVersion: v1
kind: Service
metadata:
  name: $CONFLUENT-$KAFKA_CONNECT
  namespace: $NAMESPACE
  labels:
    app: $KAFKA_CONNECT
    release: $CONFLUENT
spec:
  ports:
    - name: kafka-connect
      port: 8083
  selector:
    app: $KAFKA_CONNECT
    release: $CONFLUENT

---
apiVersion: v1
kind: Service
metadata:
  name: $CONFLUENT-$KAFKA-headless
  namespace: $NAMESPACE
  labels:
    app: $KAFKA
    release: $CONFLUENT
spec:
  ports:
    - port: 9092
      name: broker
  clusterIP: None
  selector:
    app: $KAFKA
    release: $CONFLUENT
---
apiVersion: v1
kind: Service
metadata:
  name: $CONFLUENT-$KAFKA-0-nodeport
  namespace: $NAMESPACE
  labels:
    app: $KAFKA
    release: $CONFLUENT
    pod: $CONFLUENT-$KAFKA-0
spec:
  type: NodePort
  ports:
    - name: external-broker
      port: 19092
      targetPort: $BROKER_NODEPORT0
      nodePort: $BROKER_NODEPORT0
      protocol: TCP
  selector:
    app: $KAFKA
    release: $CONFLUENT
    statefulset.kubernetes.io/pod-name: $CONFLUENT-$KAFKA-0
---
apiVersion: v1
kind: Service
metadata:
  name: $CONFLUENT-$KAFKA-1-nodeport
  namespace: $NAMESPACE
  labels:
    app: $KAFKA
    release: $CONFLUENT
    pod: $CONFLUENT-$KAFKA-1
spec:
  type: NodePort
  ports:
    - name: external-broker
      port: 19092
      targetPort: $BROKER_NODEPORT1
      nodePort: $BROKER_NODEPORT1
      protocol: TCP
  selector:
    app: $KAFKA
    release: $CONFLUENT
    statefulset.kubernetes.io/pod-name: $CONFLUENT-$KAFKA-1
---
apiVersion: v1
kind: Service
metadata:
  name: $CONFLUENT-$KAFKA-2-nodeport
  namespace: $NAMESPACE
  labels:
    app: $KAFKA
    release: $CONFLUENT
    pod: $CONFLUENT-$KAFKA-2
spec:
  type: NodePort
  ports:
    - name: external-broker
      port: 19092
      targetPort: $BROKER_NODEPORT2
      nodePort: $BROKER_NODEPORT2
      protocol: TCP
  selector:
    app: $KAFKA
    release: $CONFLUENT
    statefulset.kubernetes.io/pod-name: $CONFLUENT-$KAFKA-2
---
apiVersion: v1
kind: Service
metadata:
  name: $CONFLUENT-$KAFKA
  namespace: $NAMESPACE
  labels:
    app: $KAFKA
    release: $CONFLUENT
spec:
  ports:
    - port: 9092
      name: broker
  selector:
    app: $KAFKA
    release: $CONFLUENT
---
apiVersion: v1
kind: Service
metadata:
  name: $CONFLUENT-$SCHEMA_REGISTRY
  namespace: $NAMESPACE
  labels:
    app: $SCHEMA_REGISTRY
    release: $CONFLUENT
spec:
  ports:
    - name: schema-registry
      port: 8081
  selector:
    app: $SCHEMA_REGISTRY
    release: $CONFLUENT

---
apiVersion: v1
kind: Service
metadata:
  name: $CONFLUENT-$ZOOKEEPER-headless
  namespace: $NAMESPACE
  labels:
    app: $ZOOKEEPER
    release: $CONFLUENT
spec:
  ports:
    - port: 2888
      name: server
    - port: 3888
      name: leader-election
  clusterIP: None
  selector:
    app: $ZOOKEEPER
    release: $CONFLUENT
---
apiVersion: v1
kind: Service
metadata:
  name: $CONFLUENT-$ZOOKEEPER
  namespace: $NAMESPACE
  labels:
    app: $ZOOKEEPER
    release: $CONFLUENT
spec:
  type: 
  ports:
    - port: 2181
      name: client
  selector:
    app: $ZOOKEEPER
    release: $CONFLUENT
---
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: $CONFLUENT-cc
  namespace: $NAMESPACE
  labels:
    app: cc
    release: $CONFLUENT
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cc
      release: $CONFLUENT
  template:
    metadata:
      labels:
        app: cc
        release: $CONFLUENT
    spec:
      serviceAccountName: $PREFIX-insight
      containers:
        - name: cc
          image: $CONTROL_CENTER_IMAGE
          imagePullPolicy: IfNotPresent
          ports:
            - name: cc-http
              containerPort: 9021
              protocol: TCP
          resources:
            {}
            
          env:
            - name: CONTROL_CENTER_BOOTSTRAP_SERVERS
              value: PLAINTEXT://$CONFLUENT-$KAFKA-headless:9092
            - name: CONTROL_CENTER_ZOOKEEPER_CONNECT
              value: 
            - name: CONTROL_CENTER_CONNECT_CLUSTER
              value: http://$CONFLUENT-$KAFKA_CONNECT:8083
            - name: CONTROL_CENTER_SCHEMA_REGISTRY_URL
              value: http://$CONFLUENT-$SCHEMA_REGISTRY:8081
            - name: KAFKA_HEAP_OPTS
              value: "-Xms512M -Xmx512M"
            - name: "CONTROL_CENTER_REPLICATION_FACTOR"
              value: "3"

---
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: $CONFLUENT-$KAFKA_CONNECT
  namespace: $NAMESPACE
  labels:
    app: $KAFKA_CONNECT
    release: $CONFLUENT
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $KAFKA_CONNECT
      release: $CONFLUENT
  template:
    metadata:
      labels:
        app: $KAFKA_CONNECT
        release: $CONFLUENT
    spec:
      serviceAccountName: $PREFIX-insight
      containers:
        - name: $KAFKA_CONNECT-server
          image: $KAFKA_CONNECT_IMAGE
          imagePullPolicy: "IfNotPresent"
          ports:
            - name: kafka-connect
              containerPort: 8083
              protocol: TCP
          resources:
            {}
            
          env:
            - name: CONNECT_REST_ADVERTISED_HOST_NAME
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: CONNECT_BOOTSTRAP_SERVERS
              value: PLAINTEXT://$CONFLUENT-$KAFKA-headless:9092
            - name: CONNECT_GROUP_ID
              value: $CONFLUENT
            - name: CONNECT_CONFIG_STORAGE_TOPIC
              value: $CONFLUENT-$KAFKA_CONNECT-config
            - name: CONNECT_OFFSET_STORAGE_TOPIC
              value: $CONFLUENT-$KAFKA_CONNECT-offset
            - name: CONNECT_STATUS_STORAGE_TOPIC
              value: $CONFLUENT-$KAFKA_CONNECT-status
            - name: CONNECT_KEY_CONVERTER_SCHEMA_REGISTRY_URL
              value: http://$CONFLUENT-$SCHEMA_REGISTRY:8081
            - name: CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL
              value: http://$CONFLUENT-$SCHEMA_REGISTRY:8081
            - name: KAFKA_HEAP_OPTS
              value: "-Xms512M -Xmx512M"
            - name: "CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR"
              value: "3"
            - name: "CONNECT_INTERNAL_KEY_CONVERTER"
              value: "org.apache.kafka.connect.json.JsonConverter"
            - name: "CONNECT_INTERNAL_VALUE_CONVERTER"
              value: "org.apache.kafka.connect.json.JsonConverter"
            - name: "CONNECT_KEY_CONVERTER"
              value: "io.confluent.connect.avro.AvroConverter"
            - name: "CONNECT_KEY_CONVERTER_SCHEMAS_ENABLE"
              value: "false"
            - name: "CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR"
              value: "3"
            - name: "CONNECT_PLUGIN_PATH"
              value: "/usr/share/java,/usr/share/confluent-hub-components"
            - name: "CONNECT_STATUS_STORAGE_REPLICATION_FACTOR"
              value: "3"
            - name: "CONNECT_VALUE_CONVERTER"
              value: "io.confluent.connect.avro.AvroConverter"
            - name: "CONNECT_VALUE_CONVERTER_SCHEMAS_ENABLE"
              value: "false"
          resources: 
            requests:
              memory: "$REQUEST_KAFKA_CONNECT_MEMORY"
              cpu: "$REQUEST_KAFKA_CONNECT_CPU"         
            limits:
              memory: "$LIMIT_KAFKA_CONNECT_MEMORY"
              cpu: "$LIMIT_KAFKA_CONNECT_CPU"
---
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: $CONFLUENT-$SCHEMA_REGISTRY
  namespace: $NAMESPACE
  labels:
    app: $SCHEMA_REGISTRY
    release: $CONFLUENT
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $SCHEMA_REGISTRY
      release: $CONFLUENT
  template:
    metadata:
      labels:
        app: $SCHEMA_REGISTRY
        release: $CONFLUENT
    spec:
      serviceAccountName: $PREFIX-insight
      containers:
        - name: $SCHEMA_REGISTRY-server
          image: $SCHEMA_REGISTRY_IMAGE
          imagePullPolicy: "IfNotPresent"
          ports:
            - name: schema-registry
              containerPort: 8081
              protocol: TCP
          resources:
            {}
            
          env:
          - name: SCHEMA_REGISTRY_HOST_NAME
            valueFrom:
              fieldRef:
                fieldPath: status.podIP
          - name: SCHEMA_REGISTRY_LISTENERS
            value: http://0.0.0.0:8081
          - name: SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS
            value: PLAINTEXT://$CONFLUENT-$KAFKA-headless:9092
          - name: SCHEMA_REGISTRY_KAFKASTORE_GROUP_ID
            value: $CONFLUENT
          - name: SCHEMA_REGISTRY_MASTER_ELIGIBILITY
            value: "true"
          - name: SCHEMA_REGISTRY_HEAP_OPTS
            value: "-Xms512M -Xmx512M"
          resources: 
            requests:
              memory: "$REQUEST_SCHEMA_REGISTRY_MEMORY"
              cpu: "$REQUEST_SCHEMA_REGISTRY_CPU"         
            limits:
              memory: "$LIMIT_SCHEMA_REGISTRY_MEMORY"
              cpu: "$LIMIT_SCHEMA_REGISTRY_CPU"
EOF

sed "s#{CONFLUENT}#$CONFLUENT#g" kafka-statefullset.yaml > kafka-statefullset-deploy-tmp0.yaml
sed "s#{ZOOKEEPER}#$ZOOKEEPER#g" kafka-statefullset-deploy-tmp0.yaml >kafka-statefullset-deploy-tmp1.yaml
sed "s#{KAFKA}#$KAFKA#g" kafka-statefullset-deploy-tmp1.yaml > kafka-statefullset-deploy-tmp2.yaml
sed "s#{KAFKA_BROKER_IMAGE}#$KAFKA_BROKER_IMAGE#g" kafka-statefullset-deploy-tmp2.yaml > kafka-statefullset-deploy-tmp3.yaml
sed "s#{ZOOKEEPER_IMAGE}#$ZOOKEEPER_IMAGE#g" kafka-statefullset-deploy-tmp3.yaml > kafka-statefullset-deploy-tmp4.yaml
sed "s#{BROKER_NODEPORT0}#$BROKER_NODEPORT0#g" kafka-statefullset-deploy-tmp4.yaml > kafka-statefullset-deploy-tmp5.yaml
sed "s#{PREFIX}#$PREFIX#g" kafka-statefullset-deploy-tmp5.yaml > kafka-statefullset-deploy-tmp6.yaml
sed "s#{BROKER_NODEPORT1}#$BROKER_NODEPORT1#g" kafka-statefullset-deploy-tmp6.yaml > kafka-statefullset-deploy-tmp7.yaml
sed "s#{BROKER_NODEPORT2}#$BROKER_NODEPORT2#g" kafka-statefullset-deploy-tmp7.yaml > kafka-statefullset-deploy-tmp8.yaml
sed "s#{REQUEST_ZOOKEEPER_CPU}#$REQUEST_ZOOKEEPER_CPU#g" kafka-statefullset-deploy-tmp8.yaml > kafka-statefullset-deploy-tmp9.yaml
sed "s#{REQUEST_ZOOKEEPER_MEMORY}#$REQUEST_ZOOKEEPER_MEMORY#g" kafka-statefullset-deploy-tmp9.yaml > kafka-statefullset-deploy-tmp10.yaml
sed "s#{REQUEST_ZOOKEEPER_STORAGE}#$REQUEST_ZOOKEEPER_STORAGE#g" kafka-statefullset-deploy-tmp10.yaml > kafka-statefullset-deploy-tmp11.yaml
sed "s#{LIMIT_ZOOKEEPER_CPU}#$LIMIT_ZOOKEEPER_CPU#g" kafka-statefullset-deploy-tmp11.yaml > kafka-statefullset-deploy-tmp12.yaml
sed "s#{LIMIT_ZOOKEEPER_MEMORY}#$LIMIT_ZOOKEEPER_MEMORY#g" kafka-statefullset-deploy-tmp12.yaml > kafka-statefullset-deploy-tmp13.yaml
sed "s#{LIMIT_ZOOKEEPER_STORAGE}#$LIMIT_ZOOKEEPER_STORAGE#g" kafka-statefullset-deploy-tmp13.yaml > kafka-statefullset-deploy-tmp14.yaml
sed "s#{ZOOKEEPER_EPHERMERAL_STORAGE}#$ZOOKEEPER_EPHERMERAL_STORAGE#g" kafka-statefullset-deploy-tmp14.yaml > kafka-statefullset-deploy-tmp15.yaml
sed "s#{KAFKA_EPHERMERAL_STORAGE}#$KAFKA_EPHERMERAL_STORAGE#g" kafka-statefullset-deploy-tmp15.yaml > kafka-statefullset-deploy-tmp16.yaml
sed "s#{NAMESPACE}#$NAMESPACE#g" kafka-statefullset-deploy-tmp16.yaml > kafka-statefullset-deploy.yaml

kubectl apply -f kafka-statefullset-deploy.yaml -n $NAMESPACE

rm kafka-statefullset-deploy*