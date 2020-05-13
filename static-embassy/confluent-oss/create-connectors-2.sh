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
    "name": "core_tree_distance_result",
    "config": {
        "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
        "errors.log.include.messages": "true",
        "connection.password": "FD7tQNctPRk64pLv",
        "topics": "core_tree_distance_result",
        "connection.user": "mykrobe",
        "name": "core_tree_distance_result",
        "auto.create": "false",
        "connection.url": "jdbc:mysql://mykrobe-mysql.mykrobe-dev.svc.cluster.local:3306/mykrobe",
        "errors.log.enable": "true",
        "insert.mode": "upsert",
        "pk.fields": "experimentId, received",
        "pk.mode": "record_value"
        }
    }' http://$CONNECT_REST_ADVERTISED_HOST_NAME:8083/connectors
