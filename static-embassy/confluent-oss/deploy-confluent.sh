#!/bin/bash

source config.sh

echo ""
echo "Deploying Confluent platform using:"
echo " - Namespace: $NAMESPACE"
echo " - Prefix: $PREFIX"
echo " - Confluent: $CONFLUENT"
echo " - Control-center Image: $CONTROL_CENTER_IMAGE"
echo " - Kafka-connect Image: $KAFKA_CONNECT_IMAGE"
echo " - Schema-registry Image: $SCHEMA_REGISTRY_IMAGE"
echo " - Kafka broker Image: $KAFKA_BROKER_IMAGE"
echo " - Zookeeper Image: $ZOOKEEPER_IMAGE"
echo ""

cat <<EOF | kubectl apply -f -
---
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: $CONFLUENT-cp-zookeeper-pdb
  namespace: $NAMESPACE
  labels:
    app: cp-zookeeper
    release: $CONFLUENT
spec:
  selector:
    matchLabels:
      app: cp-zookeeper
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
  name: $CONFLUENT-cp-kafka-connect
  namespace: $NAMESPACE
  labels:
    app: cp-kafka-connect
    release: $CONFLUENT
spec:
  ports:
    - name: kafka-connect
      port: 8083
  selector:
    app: cp-kafka-connect
    release: $CONFLUENT

---
apiVersion: v1
kind: Service
metadata:
  name: $CONFLUENT-cp-kafka-headless
  namespace: $NAMESPACE
  labels:
    app: cp-kafka
    release: $CONFLUENT
spec:
  ports:
    - port: 9092
      name: broker
  clusterIP: None
  selector:
    app: cp-kafka
    release: $CONFLUENT
---
apiVersion: v1
kind: Service
metadata:
  name: $CONFLUENT-cp-kafka
  namespace: $NAMESPACE
  labels:
    app: cp-kafka
    release: $CONFLUENT
spec:
  ports:
    - port: 9092
      name: broker
  selector:
    app: cp-kafka
    release: $CONFLUENT
---
apiVersion: v1
kind: Service
metadata:
  name: $CONFLUENT-cp-schema-registry
  namespace: $NAMESPACE
  labels:
    app: cp-schema-registry
    release: $CONFLUENT
spec:
  ports:
    - name: schema-registry
      port: 8081
  selector:
    app: cp-schema-registry
    release: $CONFLUENT

---
apiVersion: v1
kind: Service
metadata:
  name: $CONFLUENT-cp-zookeeper-headless
  namespace: $NAMESPACE
  labels:
    app: cp-zookeeper
    release: $CONFLUENT
spec:
  ports:
    - port: 2888
      name: server
    - port: 3888
      name: leader-election
  clusterIP: None
  selector:
    app: cp-zookeeper
    release: $CONFLUENT
---
apiVersion: v1
kind: Service
metadata:
  name: $CONFLUENT-cp-zookeeper
  namespace: $NAMESPACE
  labels:
    app: cp-zookeeper
    release: $CONFLUENT
spec:
  type: 
  ports:
    - port: 2181
      name: client
  selector:
    app: cp-zookeeper
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
              value: PLAINTEXT://$CONFLUENT-cp-kafka-headless:9092
            - name: CONTROL_CENTER_ZOOKEEPER_CONNECT
              value: 
            - name: CONTROL_CENTER_CONNECT_CLUSTER
              value: http://$CONFLUENT-cp-kafka-connect:8083
            - name: CONTROL_CENTER_SCHEMA_REGISTRY_URL
              value: http://$CONFLUENT-cp-schema-registry:8081
            - name: KAFKA_HEAP_OPTS
              value: "-Xms512M -Xmx512M"
            - name: "CONTROL_CENTER_REPLICATION_FACTOR"
              value: "3"

---
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: $CONFLUENT-cp-kafka-connect
  namespace: $NAMESPACE
  labels:
    app: cp-kafka-connect
    release: $CONFLUENT
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cp-kafka-connect
      release: $CONFLUENT
  template:
    metadata:
      labels:
        app: cp-kafka-connect
        release: $CONFLUENT
    spec:
      containers:
        - name: cp-kafka-connect-server
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
              value: PLAINTEXT://$CONFLUENT-cp-kafka-headless:9092
            - name: CONNECT_GROUP_ID
              value: $CONFLUENT
            - name: CONNECT_CONFIG_STORAGE_TOPIC
              value: $CONFLUENT-cp-kafka-connect-config
            - name: CONNECT_OFFSET_STORAGE_TOPIC
              value: $CONFLUENT-cp-kafka-connect-offset
            - name: CONNECT_STATUS_STORAGE_TOPIC
              value: $CONFLUENT-cp-kafka-connect-status
            - name: CONNECT_KEY_CONVERTER_SCHEMA_REGISTRY_URL
              value: http://$CONFLUENT-cp-schema-registry:8081
            - name: CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL
              value: http://$CONFLUENT-cp-schema-registry:8081
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
---
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: $CONFLUENT-cp-schema-registry
  namespace: $NAMESPACE
  labels:
    app: cp-schema-registry
    release: $CONFLUENT
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cp-schema-registry
      release: $CONFLUENT
  template:
    metadata:
      labels:
        app: cp-schema-registry
        release: $CONFLUENT
    spec:
      containers:
        - name: cp-schema-registry-server
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
            value: PLAINTEXT://$CONFLUENT-cp-kafka-headless:9092
          - name: SCHEMA_REGISTRY_KAFKASTORE_GROUP_ID
            value: $CONFLUENT
          - name: SCHEMA_REGISTRY_MASTER_ELIGIBILITY
            value: "true"
          - name: SCHEMA_REGISTRY_HEAP_OPTS
            value: "-Xms512M -Xmx512M"
EOF

sed "s#{PREFIX}#$CONFLUENT#g" kafka-statefullset.yaml > kafka-statefullset-deploy-tmp.yaml
sed "s#{NAMESPACE}#$NAMESPACE#g" kafka-statefullset-deploy-tmp.yaml > kafka-statefullset-deploy.yaml

kubectl apply -f kafka-statefullset-deploy.yaml -n $NAMESPACE

rm kafka-statefullset-deploy*