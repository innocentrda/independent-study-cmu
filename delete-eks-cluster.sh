#!/bin/bash

set -e

CLUSTER_NAME="aws-cluster"

# CONFIGURABLE VARIABLES
# CLUSTER_NAME="aws-cluster"
REGION="eu-west-2"
SERVICE_ACCOUNT_NAME="ebs-csi-controller-sa"
NAMESPACE="kube-system"
SC_NAME="gp2-csi"

echo "🔍 Fetching IAM role ARN for service account..."
ROLE_NAME=$(eksctl get iamserviceaccount \
  --cluster "$CLUSTER_NAME" \
  --region "$REGION" \
  --name "$SERVICE_ACCOUNT_NAME" \
  --namespace "$NAMESPACE" \
  -o json | jq -r '.[0].status.roleName')

if [ -z "$ROLE_NAME" ]; then
  echo "⚠️  Could not find IAM role associated with service account. Skipping IAM role cleanup."
else
  echo "🗑️ Deleting IAM service account from cluster..."
  eksctl delete iamserviceaccount \
    --name "$SERVICE_ACCOUNT_NAME" \
    --namespace "$NAMESPACE" \
    --cluster "$CLUSTER_NAME" \
    --region "$REGION" \
    --wait

  echo "🔐 Detaching and deleting IAM role: $ROLE_NAME"
  ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query 'AttachedPolicies[].PolicyArn' --output text)
  for policy in $ATTACHED_POLICIES; do
    aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn "$policy"
  done

  aws iam delete-role --role-name "$ROLE_NAME"
fi

echo "💥 Deleting EKS cluster: $CLUSTER_NAME"
eksctl delete cluster --name "$CLUSTER_NAME" --region "$REGION"

echo "🧼 Cleaning up custom StorageClass (if exists)..."
kubectl delete storageclass "$SC_NAME" || echo "StorageClass $SC_NAME not found or already deleted."

# (Optional) Remove OIDC provider
echo "🔍 Attempting to remove OIDC provider (if exists)..."
OIDC_URL=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" --query "cluster.identity.oidc.issuer" --output text 2>/dev/null || true)

if [[ "$OIDC_URL" == https://* ]]; then
  OIDC_HOSTPATH=${OIDC_URL#https://}
  PROVIDER_ARN="arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):oidc-provider/$OIDC_HOSTPATH"

  echo "🔐 Deleting IAM OIDC provider: $PROVIDER_ARN"
  aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "$PROVIDER_ARN" || echo "OIDC provider not found or already deleted."
else
  echo "OIDC provider not found or already deleted."
fi

echo "✅ Cleanup complete."
