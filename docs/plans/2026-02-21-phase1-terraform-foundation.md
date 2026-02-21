# Phase 1: Terraform Foundation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Terraform の基盤をセットアップする。S3 backend、DynamoDB ロック、ディレクトリ構成、.gitignore を整備し、dev 環境で `terraform init` が通る状態にする。

**Architecture:** S3 バケットと DynamoDB テーブルを bootstrap スクリプトで作成し、Terraform の remote state backend として使用する。モジュールベースのディレクトリ構成を作り、各環境が独立した state を持つようにする。

**Tech Stack:** Terraform >= 1.6, AWS CLI, S3, DynamoDB

---

### Task 1: Terraform インストール確認 & .gitignore 更新

**Files:**
- Modify: `.gitignore`

**Step 1: Terraform がインストールされているか確認**

Run: `terraform --version`

Terraform が未インストールの場合は Homebrew でインストール:

Run: `brew install terraform`

Expected: `Terraform v1.x.x`

**Step 2: AWS CLI の認証情報が設定されているか確認**

Run: `aws sts get-caller-identity`

未設定の場合:

Run: `aws configure`

以下を入力:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `ap-northeast-1`
- Default output format: `json`

**Step 3: .gitignore に Terraform 用エントリを追加**

`.gitignore` の末尾に以下を追加:

```
# Terraform
*.tfstate
*.tfstate.*
*.tfvars
!*.tfvars.example
.terraform/
.terraform.lock.hcl
crash.log
crash.*.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
*.tfplan
```

**Step 4: Commit**

```bash
git add .gitignore
git commit -m "chore: add Terraform entries to .gitignore"
```

---

### Task 2: Bootstrap スクリプト作成（S3 + DynamoDB）

**Files:**
- Create: `scripts/bootstrap-backend.sh`

**Step 1: scripts ディレクトリを作成**

Run: `mkdir -p scripts`

**Step 2: bootstrap スクリプトを作成**

`scripts/bootstrap-backend.sh`:

```bash
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
```

**Step 3: 実行権限を付与**

Run: `chmod +x scripts/bootstrap-backend.sh`

**Step 4: Commit**

```bash
git add scripts/bootstrap-backend.sh
git commit -m "feat: add bootstrap script for Terraform S3 backend and DynamoDB lock"
```

---

### Task 3: Global 環境の Terraform 設定

**Files:**
- Create: `terraform/global/providers.tf`
- Create: `terraform/global/backend.tf`
- Create: `terraform/global/variables.tf`
- Create: `terraform/global/outputs.tf`
- Create: `terraform/global/main.tf`

**Step 1: ディレクトリを作成**

Run: `mkdir -p terraform/global`

**Step 2: providers.tf を作成**

`terraform/global/providers.tf`:

```hcl
terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
    }
  }
}
```

**Step 3: backend.tf を作成**

`terraform/global/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "airas-terraform-state-427979936961"
    key            = "global/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "airas-terraform-lock"
    encrypt        = true
  }
}
```

**Step 4: variables.tf を作成**

`terraform/global/variables.tf`:

```hcl
variable "project" {
  description = "Project name used for resource naming"
  type        = string
  default     = "airas"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}
```

**Step 5: outputs.tf を作成**

`terraform/global/outputs.tf`:

```hcl
# Outputs will be added as global resources are created
```

**Step 6: main.tf を作成**

`terraform/global/main.tf`:

```hcl
# Global resources (ECR repositories, IAM roles, etc.)
# Will be populated in later phases
```

**Step 7: Commit**

```bash
git add terraform/global/
git commit -m "feat: add Terraform global environment configuration"
```

---

### Task 4: Dev 環境の Terraform 設定

**Files:**
- Create: `terraform/environments/dev/providers.tf`
- Create: `terraform/environments/dev/backend.tf`
- Create: `terraform/environments/dev/variables.tf`
- Create: `terraform/environments/dev/outputs.tf`
- Create: `terraform/environments/dev/main.tf`
- Create: `terraform/environments/dev/terraform.tfvars.example`

**Step 1: ディレクトリを作成**

Run: `mkdir -p terraform/environments/dev`

**Step 2: providers.tf を作成**

`terraform/environments/dev/providers.tf`:

```hcl
terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
```

**Step 3: backend.tf を作成**

`terraform/environments/dev/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "airas-terraform-state-427979936961"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "airas-terraform-lock"
    encrypt        = true
  }
}
```

**Step 4: variables.tf を作成**

`terraform/environments/dev/variables.tf`:

```hcl
variable "project" {
  description = "Project name used for resource naming"
  type        = string
  default     = "airas"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}
```

**Step 5: outputs.tf を作成**

`terraform/environments/dev/outputs.tf`:

```hcl
# Outputs will be added as resources are created
```

**Step 6: main.tf を作成**

`terraform/environments/dev/main.tf`:

```hcl
# Dev environment resources
# Modules will be added in subsequent phases
```

**Step 7: terraform.tfvars.example を作成**

`terraform/environments/dev/terraform.tfvars.example`:

```hcl
project     = "airas"
environment = "dev"
aws_region  = "ap-northeast-1"
```

**Step 8: Commit**

```bash
git add terraform/environments/dev/
git commit -m "feat: add Terraform dev environment configuration"
```

---

### Task 5: Staging 環境の Terraform 設定

**Files:**
- Create: `terraform/environments/staging/providers.tf`
- Create: `terraform/environments/staging/backend.tf`
- Create: `terraform/environments/staging/variables.tf`
- Create: `terraform/environments/staging/outputs.tf`
- Create: `terraform/environments/staging/main.tf`
- Create: `terraform/environments/staging/terraform.tfvars.example`

**Step 1: dev 環境をコピーして staging 用に修正**

dev と同じ構成で、以下を変更:
- `backend.tf`: key を `staging/terraform.tfstate` に
- `variables.tf`: environment の default を `staging` に
- `terraform.tfvars.example`: environment を `staging` に

**Step 2: Commit**

```bash
git add terraform/environments/staging/
git commit -m "feat: add Terraform staging environment configuration"
```

---

### Task 6: Prod 環境の Terraform 設定

**Files:**
- Create: `terraform/environments/prod/providers.tf`
- Create: `terraform/environments/prod/backend.tf`
- Create: `terraform/environments/prod/variables.tf`
- Create: `terraform/environments/prod/outputs.tf`
- Create: `terraform/environments/prod/main.tf`
- Create: `terraform/environments/prod/terraform.tfvars.example`

**Step 1: dev 環境をコピーして prod 用に修正**

dev と同じ構成で、以下を変更:
- `backend.tf`: key を `prod/terraform.tfstate` に
- `variables.tf`: environment の default を `prod` に
- `terraform.tfvars.example`: environment を `prod` に

**Step 2: Commit**

```bash
git add terraform/environments/prod/
git commit -m "feat: add Terraform prod environment configuration"
```

---

### Task 7: Modules ディレクトリの雛形作成

**Files:**
- Create: `terraform/modules/.gitkeep`

**Step 1: modules ディレクトリを作成**

Run: `mkdir -p terraform/modules && touch terraform/modules/.gitkeep`

**Step 2: Commit**

```bash
git add terraform/modules/.gitkeep
git commit -m "chore: add modules directory placeholder"
```

---

### Task 8: Bootstrap 実行 & terraform init 検証

**Step 1: Bootstrap スクリプトを実行**

Run: `./scripts/bootstrap-backend.sh`

Expected: S3 バケットと DynamoDB テーブルが作成される

**Step 2: Global 環境で terraform init**

Run: `cd terraform/global && terraform init`

Expected: `Terraform has been successfully initialized!`

**Step 3: Dev 環境で terraform init**

Run: `cd terraform/environments/dev && terraform init`

Expected: `Terraform has been successfully initialized!`

**Step 4: terraform plan で空のプランを確認**

Run: `terraform plan`

Expected: `No changes. Your infrastructure matches the configuration.`

**Step 5: 成功を確認して完了**

Phase 1 完了。Phase 2 (VPC + ネットワーク) へ進む準備ができた状態。
