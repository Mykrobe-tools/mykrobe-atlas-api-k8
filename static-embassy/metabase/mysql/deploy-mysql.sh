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
echo "Limits:"
echo " - Request CPU: $REQUEST_CPU"
echo " - Request Memory: $REQUEST_MEMORY"
echo " - Request Storage: $REQUEST_STORAGE"
echo " - Limit CPU: $LIMIT_CPU"
echo " - Limit Memory: $LIMIT_MEMORY"
echo " - Limit Storage: $LIMIT_STORAGE"
echo ""

cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: $PREFIX-mysql
  name: $PREFIX-mysql-sa
  namespace: $NAMESPACE
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
  storageClassName: nfs-client
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
sed "s#{REQUEST_MEMORY}#$REQUEST_MEMORY#g" mysql-deployment-tmp3.yaml > mysql-deployment-tmp4.yaml
sed "s#{REQUEST_CPU}#$REQUEST_CPU#g" mysql-deployment-tmp4.yaml > mysql-deployment-tmp5.yaml
sed "s#{REQUEST_STORAGE}#$REQUEST_STORAGE#g" mysql-deployment-tmp5.yaml > mysql-deployment-tmp6.yaml
sed "s#{LIMIT_MEMORY}#$LIMIT_MEMORY#g" mysql-deployment-tmp6.yaml > mysql-deployment-tmp7.yaml
sed "s#{LIMIT_CPU}#$LIMIT_CPU#g" mysql-deployment-tmp7.yaml > mysql-deployment-tmp8.yaml
sed "s#{LIMIT_STORAGE}#$LIMIT_STORAGE#g" mysql-deployment-tmp8.yaml > mysql-deployment-tmp9.yaml
sed "s#{DB_USER}#$DB_USER#g" mysql-deployment-tmp9.yaml > mysql-deployment-resolved.yaml

kubectl apply -f mysql-deployment-resolved.yaml

rm mysql-deployment-*
