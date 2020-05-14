#!/bin/bash

echo ""
echo "Deploying Mysql using:"
echo " - Namespace: $NAMESPACE"
echo " - Prefix: $PREFIX"
echo " - Mysql Image: $MYSQL_IMAGE"
echo " - Database Name: $DATABASE"
echo " - Database User: $DB_USER"
echo " - User Password: $DB_PASSWORD"
echo " - Root Password: $ROOT_PASSWORD"
echo ""

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Secret
metadata:
  name: $PREFIX-mysql
  namespace: $NAMESPACE
  labels:
    app: $PREFIX-mysql
type: Opaque
data:
  mysql-root-password: $ROOT_PASSWORD
  mysql-password: $DB_PASSWORD
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: $PREFIX-mysql
  namespace: $NAMESPACE
  labels:
    app: $PREFIX-mysql
spec:
  accessModes:
    - "ReadWriteOnce"
  resources:
    requests:
      storage: "8Gi"
---
apiVersion: v1
kind: Service
metadata:
  name: $PREFIX-mysql
  namespace: $NAMESPACE
  labels:
    app: $PREFIX-mysql
  annotations:
spec:
  type: ClusterIP
  ports:
  - name: mysql
    port: 3306
    targetPort: mysql
  selector:
    app: $PREFIX-mysql
EOF

sed "s#{NAMESPACE}#$NAMESPACE#g" mysql-deployment.yaml > mysql-deployment-tmp0.yaml
sed "s#{PREFIX}#$PREFIX#g" mysql-deployment-tmp0.yaml > mysql-deployment-tmp1.yaml
sed "s#{MYSQL_IMAGE}#$MYSQL_IMAGE#g" mysql-deployment-tmp1.yaml > mysql-deployment-tmp2.yaml
sed "s#{DATABASE}#$DATABASE#g" mysql-deployment-tmp2.yaml > mysql-deployment-tmp3.yaml
sed "s#{DB_USER}#$DB_USER#g" mysql-deployment-tmp3.yaml > mysql-deployment-resolved.yaml

kubectl apply -f mysql-deployment-resolved.yaml

rm mysql-deployment-*
