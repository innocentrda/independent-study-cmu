#!/bin/bash

set -e

# NETWORK-CLUSTER
CLUSTER_NAME="aws-cluster"

# # NETWORK-CLUSTER
# CLUSTER_NAME="compute-cluster"

# # STORAGE-CLUSTER
# CLUSTER_NAME="storage-cluster"

# CONFIGURABLE VARIABLES
REGION="eu-west-2"
NODEGROUP_NAME="linux-nodes"
NODE_TYPE="c6i.2xlarge"
NODE_COUNT=4
SERVICE_ACCOUNT_NAME="ebs-csi-controller-sa"
NAMESPACE="kube-system"
POLICY_ARN="arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
SC_NAME="gp2-csi"

# Create EKS Cluster
echo "🚀 Creating EKS cluster: $CLUSTER_NAME"
eksctl create cluster \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  --nodegroup-name "$NODEGROUP_NAME" \
  --node-type "$NODE_TYPE" \
  --nodes "$NODE_COUNT" \
  --managed \
  --with-oidc

# Associate IAM OIDC Provider (if not already)
echo "🔗 Associating OIDC provider"
eksctl utils associate-iam-oidc-provider \
  --region "$REGION" \
  --cluster "$CLUSTER_NAME" \
  --approve

# Create IAM service account for EBS CSI driver
echo "🔐 Creating IAM service account: $SERVICE_ACCOUNT_NAME"
eksctl create iamserviceaccount \
  --name "$SERVICE_ACCOUNT_NAME" \
  --namespace "$NAMESPACE" \
  --cluster "$CLUSTER_NAME" \
  --region "$REGION" \
  --attach-policy-arn "$POLICY_ARN" \
  --approve

# Get IAM Role ARN for the service account
ROLE_ARN=$(eksctl get iamserviceaccount \
  --cluster "$CLUSTER_NAME" \
  --region "$REGION" \
  --name "$SERVICE_ACCOUNT_NAME" \
  --namespace "$NAMESPACE" \
  -o json | jq -r '.[0].status.roleARN')

# Install the AWS EBS CSI Driver addon
echo "📦 Installing EBS CSI driver addon"
eksctl create addon \
  --name aws-ebs-csi-driver \
  --cluster "$CLUSTER_NAME" \
  --region "$REGION" \
  --service-account-role-arn "$ROLE_ARN" \
  --force

# Wait a few seconds for the CSI driver pods to be ready
echo "⏳ Waiting for CSI driver to become ready..."
sleep 20

# Create a default gp2-csi StorageClass
echo "💾 Creating default StorageClass: $SC_NAME"
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: $SC_NAME
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
parameters:
  type: gp2
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF

echo "✅ EKS cluster '$CLUSTER_NAME' with EBS CSI provisioning is ready!"
