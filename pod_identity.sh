#!/bin/bash
set -e

CLUSTER_NAME="my-eks-cluster"
REGION="us-west-2"
NAMESPACE="zeus-webapp"
SERVICE_ACCOUNT="webapp-service-account"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

POD_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/webapp-pod-role"

echo "Creating namespace..."
kubectl create namespace ${NAMESPACE}

echo "Creating ServiceAccount..."
kubectl create serviceaccount ${SERVICE_ACCOUNT} \
    --namespace ${NAMESPACE}

echo "Creating Pod Identity Association..."
aws eks create-pod-identity-association \
    --cluster-name ${CLUSTER_NAME} \
    --region ${REGION} \
    --namespace ${NAMESPACE} \
    --service-account ${SERVICE_ACCOUNT} \
    --role-arn ${POD_ROLE_ARN}

echo "Done."