# AIRAS Infrastructure

AIRAS プロジェクトの AWS インフラを Terraform で管理するリポジトリです。

## 概要

| 項目 | 内容 |
|------|------|
| クラウド | AWS |
| リージョン | ap-northeast-1 (東京) |
| IaC ツール | Terraform (>= 1.5) |
| 環境 | dev / staging / prod |
| AWS アカウント | 427979936961 |

## アーキテクチャ

```
                    ┌─────────────────────────────────────────────────┐
                    │                   AWS Cloud                     │
                    │                                                 │
  ユーザー ──────▶  │  CloudFront ──▶ S3 (React/Vite フロントエンド)  │
                    │                                                 │
                    │  Route 53 ──▶ ALB ──▶ ECS Fargate (FastAPI)    │
                    │                           │                     │
                    │                      RDS PostgreSQL             │
                    │                                                 │
                    │  WAF (prod のみ)                                │
                    │  Secrets Manager / CloudWatch                   │
                    └─────────────────────────────────────────────────┘
```

### 技術スタック

- **フロントエンド**: React (Vite) → S3 + CloudFront で配信
- **バックエンド**: FastAPI (Python) → ECS Fargate で実行
- **データベース**: RDS PostgreSQL 16
- **ドメイン**: Route 53 + ACM (後日取得予定)

## ディレクトリ構成

```
terraform/
├── modules/                    # 再利用可能な Terraform モジュール
│   ├── vpc/                    #   VPC, サブネット, NAT Gateway
│   ├── ecr/                    #   ECR リポジトリ
│   ├── ecs/                    #   ECS Cluster, Service, Task Definition
│   ├── rds/                    #   RDS PostgreSQL
│   ├── s3-cloudfront/          #   S3 + CloudFront
│   ├── secrets/                #   Secrets Manager
│   ├── dns/                    #   Route 53 + ACM
│   ├── monitoring/             #   CloudWatch
│   └── waf/                    #   WAF
├── environments/
│   ├── dev/                    # 開発環境
│   ├── staging/                # ステージング環境
│   └── prod/                   # 本番環境
├── global/                     # 環境横断リソース (ECR, IAM)
scripts/
└── bootstrap-backend.sh        # Terraform backend 初期セットアップ
```

## 環境別スペック

### ネットワーク (VPC)

| | dev | staging | prod |
|--|-----|---------|------|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| Public Subnet | 2 (ALB, NAT GW) | 2 | 2 |
| Private Subnet | 2 (ECS, RDS) | 2 | 2 |
| NAT Gateway | 1 | 1 | 2 (冗長構成) |
| AZ | 2 | 2 | 2 |

### コンピュート (ECS Fargate)

| | dev | staging | prod |
|--|-----|---------|------|
| CPU | 256 (0.25 vCPU) | 512 | 1024 |
| メモリ | 512 MB | 1024 MB | 2048 MB |
| タスク数 | 1 | 1 | 2 (最小) |
| オートスケール | なし | なし | 2-4 |

### データベース (RDS PostgreSQL 16)

| | dev | staging | prod |
|--|-----|---------|------|
| インスタンス | db.t3.small | db.t3.small | db.r6g.large |
| ストレージ | 20 GB | 20 GB | 50 GB |
| Multi-AZ | No | No | Yes |
| バックアップ保持 | 7日 | 7日 | 30日 |
| 削除保護 | No | No | Yes |

### フロントエンド (S3 + CloudFront)

- S3 バケット: `airas-{env}-frontend`
- CloudFront OAC で S3 アクセス制限
- SPA 用 404 → index.html リダイレクト
- WAF は prod のみ

## Terraform State 管理

| リソース | 値 |
|----------|------|
| S3 バケット | airas-terraform-state-427979936961 |
| DynamoDB テーブル | airas-terraform-lock |
| リージョン | ap-northeast-1 |

各環境の state パス: `global/`, `dev/`, `staging/`, `prod/`

## 実装フェーズ

| # | フェーズ | 状態 |
|---|---------|------|
| 1 | Terraform 基盤 (S3 backend, ディレクトリ構成) | 完了 |
| 2 | VPC + ネットワーク | 未着手 |
| 3 | ECR + ECS Fargate + ALB | 未着手 |
| 4 | RDS PostgreSQL | 未着手 |
| 5 | S3 + CloudFront | 未着手 |
| 6 | Secrets Manager | 未着手 |
| 7 | Route 53 + ACM (ドメイン取得後) | 未着手 |
| 8 | CI/CD パイプライン | 未着手 |
| 9 | CloudWatch 監視 | 未着手 |
| 10 | WAF | 未着手 |

## ブランチ運用

```
feature/xxx → develop → main
                ↑          ↑
           開発統合      本番リリース
```

## セットアップ手順

### 前提条件

- Terraform >= 1.5
- AWS CLI (認証設定済み)
- AWS アカウントへの AdministratorAccess

### 初回セットアップ

```bash
# 1. Terraform backend の作成 (初回のみ)
./scripts/bootstrap-backend.sh

# 2. 対象環境で初期化
cd terraform/environments/dev
terraform init

# 3. プラン確認
terraform plan

# 4. 適用
terraform apply
```
