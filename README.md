# AIRAS Infrastructure

AIRAS プロジェクトの AWS インフラを Terraform で管理するリポジトリです。

| 項目 | 内容 |
|------|------|
| クラウド | AWS (ap-northeast-1) |
| IaC | Terraform >= 1.6 |
| 環境 | dev / prod |

## ドキュメント

| ドキュメント | 内容 |
|---|---|
| [アーキテクチャ](docs/architecture.md) | 全体構成図、リクエストフロー、CI/CD パイプライン |
| [インフラ詳細](docs/infrastructure-details.md) | 各サービスの設定、セキュリティ、監視、コスト見積もり |
| [技術スタック一覧](docs/tech-stack.md) | AWS サービス、アプリケーション技術、外部サービス |
| [リポジトリ構成](docs/repository-structure.md) | マルチリポジトリ戦略、ディレクトリ構成、ブランチ運用 |
| [環境構成](docs/environments.md) | dev / prod の詳細スペックと比較 |

## セットアップ

### 前提条件

```bash
# AWS CLI v2 のインストール (未インストールの場合)
./scripts/install-aws-cli.sh

# AWS 認証情報の設定
aws configure
# AWS Access Key ID:     <アクセスキーを入力>
# AWS Secret Access Key: <シークレットキーを入力>
# Default region name:   ap-northeast-1
# Default output format: json
```

### Terraform の初期化と実行

```bash
# 1. Terraform backend の作成 (初回のみ)
./scripts/bootstrap-backend.sh

# 2. 対象環境で初期化
cd terraform/environments/dev
terraform init

# 3. プラン確認 & 適用
terraform plan
terraform apply
```

## 実装フェーズ

| # | フェーズ | 状態 |
|---|---------|------|
| 1 | Terraform 基盤 (S3 backend, ディレクトリ構成) | 完了 |
| 2 | VPC + ネットワーク | 完了 |
| 3 | ECR + ECS Fargate + ALB | 完了 |
| 4 | RDS PostgreSQL | 未着手 |
| 5 | S3 + CloudFront | 完了 |
| 6 | Secrets Manager | 未着手 |
| 7 | Route 53 + ACM (ドメイン取得後) | 未着手 |
| 8 | CI/CD パイプライン | 完了 |
| 9 | CloudWatch 監視 | 未着手 |
| 10 | WAF | 完了 |
