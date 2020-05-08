echo "Waiting for Kafka Connect to start listening on kafka-connect  "
while :; do
    # Check if the connector endpoint is ready
    # If not check again
    curl_status=$(curl -s -o /dev/null -w %{http_code} http://localhost:8083/connectors)
    echo -e $(date) "Kafka Connect listener HTTP state: " $curl_status " (waiting for 200)"
    if [ $curl_status -eq 200 ]; then
        break
    fi
    sleep 5
done

echo "======> Creating connectors"
# Send a simple POST request to create the connector
curl -X POST \
    -H "Content-Type: application/json" \
    --data '{
    "name": "mykrobe-connector",
    "config": {
        "connector.class": "io.debezium.connector.mongodb.MongoDbConnector",
        "tasks.max": 1,
        "mongodb.hosts" : "mykrobe-mongodb-replicaset-client.mykrobe-dev.svc.cluster.local:27017",
        "mongodb.name" : "mykrobe",
        "mongodb.user" : "admin",
        "mongodb.password" : "<admin_password>",
        "mongodb.members.auto.discover": "true",
        "mongodb.ssl.enabled": "false",
        "database.blacklist": "config",
        "transforms.unwrap.type": "io.debezium.connector.mongodb.transforms.UnwrapFromMongoDbEnvelope",
        "key.converter": "org.apache.kafka.connect.storage.StringConverter",
        "value.converter": "org.apache.kafka.connect.json.JsonConverter",
        "database.history.kafka.bootstrap.servers" : "mykrobe-confluent-kafka.mykrobe-dev.svc.cluster.local:9092"
        }
    }' http://$CONNECT_REST_ADVERTISED_HOST_NAME:8083/connectors

curl -X POST \
    -H "Content-Type: application/json" \
    --data '{
    "name": "experiments",
    "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
      "errors.log.include.messages": "true",
      "connection.password": "<password>",
      "topics": "experiments",
      "connection.user": "mykrobe",
      "name": "mykrobe_experiments",
      "auto.create": "false",
      "connection.url": "jdbc:mysql://mykrobe-mysql.mykrobe-dev.svc.cluster.local:3306/mykrobe",
      "errors.log.enable": "true",
      "insert.mode": "upsert",
      "pk.fields": "id",
      "pk.mode": "record_value"
    }
  }' http://$CONNECT_REST_ADVERTISED_HOST_NAME:8083/connectors