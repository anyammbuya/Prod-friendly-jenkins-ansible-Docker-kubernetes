#!/bin/bash

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create the access entry for EC2 nodes
aws eks create-access-entry \
  --cluster-name my-eks-cluster \
  --principal-arn arn:aws:iam::${ACCOUNT_ID}:role/custom-node-role \
  --type EC2

# Associate the auto node policy
aws eks associate-access-policy \
  --cluster-name my-eks-cluster \
  --principal-arn arn:aws:iam::${ACCOUNT_ID}:role/custom-node-role \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSAutoNodePolicy \
  --access-scope type=cluster
    