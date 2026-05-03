#!/bin/bash
set -e

echo "===== Updating system ====="
dnf update -y

# install kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.34.2/2025-11-13/bin/linux/arm64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin

# install eksctl
ARCH=arm64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
install -m 0755 /tmp/eksctl /usr/local/bin && rm /tmp/eksctl

echo "====Create a default cluster deployment file===="

cat <<'EOF'> /opt/cluster.yml 
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: my-eks-cluster
  region: us-west-2
  version: "1.34"

vpc:
  id: "vpc-0b38adf70c98653b5"
  subnets:
    private:
      us-west-2a:
          id: "subnet-0055709509dbcf094"
      us-west-2b:
          id: "subnet-05c17377afa58645b"
  clusterEndpoints:
    publicAccess: true
    privateAccess: true

  nat:
    gateway: Disable

autoModeConfig:
    enabled: false

managedNodeGroups:
  - name: standard-nodes
    privateNetworking: true
    instanceType: t4g.small
    minSize: 2
    maxSize: 3
    desiredCapacity: 2
    volumeSize: 20
	
#verify by
kubectl get nodes
#kubectl cluster-info
#kubectl config view
EOF
    
echo "====Create a kubernetes Deployment==="

cat <<'EOF'> /opt/deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
 name: webapp-deployment
 labels:
   app: mywebapp
spec:
 replicas: 3
 selector:
   matchLabels:
     app: mywebapp
 template:
   metadata:
     labels:
       app: mywebapp
   spec:
     containers:
     - name: mywebapp
       image: anyammbuya/mywebapp:v1
       imagePullPolicy: Always
       ports:
       - containerPort: 8080
 strategy:
   type: RollingUpdate
   rollingUpdate:
     maxSurge: 1
     maxUnavailable: 1

#verify by
#kubectl get deploy
#kubectl get pods -o wide
EOF

echo "===Create a k8s service==="

cat << 'EOF' > /opt/service.yml
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
  labels:
   app: mywebapp
spec:
  selector:
    app: mywebapp
  ports:
    - port: 80
      targetPort: 8080
  
  type: ClusterIP
#verify by
#kubectl get service webapp-service
EOF

echo "===Create an Ingress resource==="

cat << 'EOF' > /opt/ingress.yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    # Add an SSL Certificate ARN here later for HTTPS
    # alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-west-2:xxx:certificate/yyy
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: webapp-service
                port:
                  number: 80

#verify by
#kubectl get ingress webapp-ingress
#kubectl describe ingress webapp-ingress
EOF

cat << 'EOF' > /opt/albcontroller.sh

# Ensure that this script runs only when the aws-load-balancer controller is absent
kubectl get deployment aws-load-balancer-controller -n kube-system >/dev/null 2>&1 && exit 0

# 1. Associate OIDC provider (allows pods to assume IAM roles)
eksctl utils associate-iam-oidc-provider --cluster my-eks-cluster --approve --region us-west-2

# 2. Download IAM policy for the controller
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.14.0/docs/install/iam_policy.json

# 3. Create IAM policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# 4. Create a ServiceAccount and IAM Role
eksctl create iamserviceaccount \
  --cluster=my-eks-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy \
  --region us-west-2 \
  --approve \
  --override-existing-serviceaccounts
  
# check service account creation
# kubectl get sa aws-load-balancer-controller -n kube-system -o yaml

# 5. Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# 6. Install the controller using Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# verify the creation of the controller and the its pods
# kubectl get deployment -n kube-system aws-load-balancer-controller
# kubectl get pods -n kube-system | grep load-balancer

EOF
chmod 700 /opt/albcontroller.sh

# Permanently set hostname to dockerhost
# -----------------------------
hostnamectl set-hostname k8sBootstrapHost

# Ensure hostname persists across reboots (Amazon Linux 2023 handles this automatically)
echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg

# eksctl create cluster --name zeusCluster --dry-run
# This command will tell you what resources you cluster will have upfront without creating the cluster
# https://kubespec.dev/         This link will help you write yaml documents for kubernetes