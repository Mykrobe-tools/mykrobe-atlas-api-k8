#!/usr/bin/env bash

# ./1.sh markthomsit argent
# http://docs.embassy.ebi.ac.uk/userguide/Embassy_Hosted_Kubernetes.html#organizing-cluster-access-using-kubeconfig-files

user=$1
project=$2

# DIR where the current script resides
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Prepare the environment
kubectl config use-context ${project}
rm ${DIR}/${user}-config ${DIR}/*.crt ${DIR}/*.csr ${DIR}/*.key
kubectl delete clusterrolebinding/${user}-cluster-admin CertificateSigningRequest/${user}-${project}

# Generate SSL ${user}.key and ${user}.csr
openssl req -new -newkey rsa:4096 -nodes -keyout ${DIR}/${user}.key -out ${DIR}/${user}.csr \
    -subj "/CN=${user}/O=${project}"

# Apprrove signing request
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
    name: ${user}-${project}
spec:
    groups:
    - system:authenticated
    request: $(cat ${user}.csr | base64 | tr -d '\n')
    usages:
    - client auth
EOF
kubectl certificate approve ${user}-${project}
kubectl get csr

# Download certificates ${user}-${project}.crt and k8s-ca.crt
kubectl get csr ${user}-${project} -o jsonpath='{.status.certificate}' \
    | base64 --decode > ${DIR}/${user}-${project}.crt
kubectl config view -o jsonpath='{.clusters[?(@.name=="'"${project}"'")].cluster.certificate-authority-data}' --raw  \
    | base64 --decode - > k8s-ca.crt

#kubectl create namespace ${project}

# Set cluster and credeentials
SERVER=$(kubectl config view -o jsonpath='{.clusters[?(@.name=="'"${project}"'")].cluster.server}')
kubectl config set-cluster ${project} --server=${SERVER} --certificate-authority=${DIR}/k8s-ca.crt --kubeconfig=${DIR}/${user}-config --embed-certs
kubectl config set-credentials ${user}  --cluster=${project} --client-certificate=${DIR}/${user}-${project}.crt  --client-key=${DIR}/${user}.key --kubeconfig=${DIR}/${user}-config

# Create context --namespace=${project}
kubectl config set-context ${user}-${project}-context --cluster=${project} --user=${user}  --kubeconfig=${DIR}/${user}-config
kubectl config use-context ${user}-${project}-context --kubeconfig=${DIR}/${user}-config
kubectl config get-contexts --kubeconfig=${DIR}/${user}-config

# Creaeete cluster role binding
kubectl get nodes --kubeconfig=${DIR}/${user}-config
kubectl create clusterrolebinding ${user}-cluster-admin --clusterrole=cluster-admin --user=${user}
kubectl get clusterrolebinding ${user}-cluster-admin
kubectl get nodes --kubeconfig=${DIR}/${user}-config
