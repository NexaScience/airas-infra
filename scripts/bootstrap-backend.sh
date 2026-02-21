#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="ap-northeast-1"
BUCKET_NAME="airas-terraform-state-427979936961"
DYNAMODB_TABLE="airas-terraform-lock"

echo "=== Creating S3 bucket for Terraform state ==="
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "Bucket $BUCKET_NAME already exists, skipping."
else
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION"
  echo "Bucket $BUCKET_NAME created."
fi

echo "=== Enabling versioning ==="
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

echo "=== Enabling server-side encryption ==="
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'

echo "=== Blocking public access ==="
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "=== Creating DynamoDB table for state locking ==="
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" >/dev/null 2>&1; then
  echo "Table $DYNAMODB_TABLE already exists, skipping."
else
  aws dynamodb create-table \
    --table-name "$DYNAMODB_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$AWS_REGION"
  echo "Table $DYNAMODB_TABLE created."
fi

echo ""
echo "=== Bootstrap complete ==="
echo "S3 Bucket:      $BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo "Region:         $AWS_REGION"
