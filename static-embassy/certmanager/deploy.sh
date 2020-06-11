echo ""
echo "Deploying atlas api using:"
echo " - Namespace: $NAMESPACE"
echo " - Name: $NAME"
echo " - Version: $VERSION"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
EOF

helm install \
  --name $NAME \
  --namespace $NAMESPACE \
  --version v0.15.1 \
  --set installCRDs=true \
  jetstack/cert-manager 

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
---
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-key
  namespace: kube-system
type: Opaque
data:
  api-key: ZmU5YjJkYTgyMmIzMDA1Yzk0YmUzZjI3NDQ5YmM5MjNhNjdiNg==
---
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: mark@makeandship.com

    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: account-key-letsencrypt-prod

    # ACME DNS-01 provider configurations
    solvers:
      - selector: {}
        dns01:
          name: cf-dns
          cloudflare:
            email: cloudflare@makeandship.com
            apiKeySecretRef:
              name: cloudflare-api-key
              key: api-key
EOF