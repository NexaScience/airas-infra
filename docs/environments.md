# 環境構成 (dev / staging / prod)

## 概要

3 つの環境を Terraform の環境別ディレクトリで管理しています。

```
単一 AWS アカウント (427979936961)
├── dev      (ECS: airas-dev-*,     RDS: airas-dev,     S3: airas-dev-frontend)
├── staging  (ECS: airas-staging-*, RDS: airas-staging, S3: airas-staging-frontend)
└── prod     (ECS: airas-prod-*,    RDS: airas-prod,    S3: airas-prod-frontend)
```

---

## dev（開発環境）

開発者が機能開発・テストを行うための環境です。コスト最小構成で運用します。

| 項目 | 設定 |
|---|---|
| **デプロイトリガー** | `develop` ブランチへの push |
| **ドメイン** | `dev.airas.example.com` |
| **VPC CIDR** | 10.0.0.0/16 |

### リソーススペック

| リソース | スペック |
|---|---|
| ECS Fargate | 0.25 vCPU / 512 MB / 1 タスク / Auto Scaling なし |
| RDS | db.t3.small / 20 GB / Single-AZ / バックアップ 7 日 / 削除保護なし |
| NAT Gateway | 1（シングル AZ） |
| WAF | なし |
| ログ保持 | 7 日 |

### 月額コスト概算: ~$92

---

## staging（ステージング環境）

本番リリース前の検証環境です。本番に近い構成で、品質確認・パフォーマンステストを行います。

| 項目 | 設定 |
|---|---|
| **デプロイトリガー** | `staging` ブランチへの push |
| **ドメイン** | `staging.airas.example.com` |
| **VPC CIDR** | 10.1.0.0/16 |

### リソーススペック

| リソース | スペック |
|---|---|
| ECS Fargate | 0.5 vCPU / 1024 MB / 1 タスク / Auto Scaling なし |
| RDS | db.t3.small / 20 GB / Single-AZ / バックアップ 7 日 / 削除保護なし |
| NAT Gateway | 1（シングル AZ） |
| WAF | なし |
| ログ保持 | 30 日 |

---

## prod（本番環境）

エンドユーザーに提供する本番環境です。高可用性・セキュリティ・監視を強化しています。

| 項目 | 設定 |
|---|---|
| **デプロイトリガー** | `main` ブランチへの push（承認ゲート付き） |
| **ドメイン** | `app.airas.example.com` / `api.airas.example.com` |
| **VPC CIDR** | 10.2.0.0/16 |

### リソーススペック

| リソース | スペック |
|---|---|
| ECS Fargate | 1 vCPU / 2048 MB / 最小 2 タスク / Auto Scaling 2-4（CPU 70% ターゲット） |
| RDS | db.r6g.large / 50 GB / **Multi-AZ** / バックアップ 30 日 / **削除保護あり** |
| NAT Gateway | **2（冗長構成）** |
| WAF | **有効**（AWS Managed Rules + レートリミット） |
| ログ保持 | 90 日 |

### 月額コスト概算: ~$250

---

## 環境比較表

| | dev | staging | prod |
|--|-----|---------|------|
| **VPC CIDR** | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| **ECS CPU** | 256 | 512 | 1024 |
| **ECS メモリ** | 512 MB | 1024 MB | 2048 MB |
| **ECS タスク数** | 1 | 1 | 2-4 |
| **Auto Scaling** | なし | なし | CPU 70% ターゲット |
| **RDS インスタンス** | db.t3.small | db.t3.small | db.r6g.large |
| **RDS ストレージ** | 20 GB | 20 GB | 50 GB |
| **Multi-AZ** | No | No | Yes |
| **バックアップ保持** | 7 日 | 7 日 | 30 日 |
| **削除保護** | No | No | Yes |
| **NAT Gateway** | 1 | 1 | 2 |
| **WAF** | なし | なし | あり |
| **ログ保持** | 7 日 | 30 日 | 90 日 |
| **デプロイ** | 自動 | 自動 | 承認ゲート付き |

---

## ドメイン・DNS

Route 53 で管理（ドメイン取得後に有効化）:

```
app.airas.example.com      → CloudFront (フロントエンド SPA)
api.airas.example.com      → CloudFront → ALB (バックエンド API)
dev.airas.example.com      → dev 環境 CloudFront
staging.airas.example.com  → staging 環境 CloudFront
```

---

## 将来計画: マルチアカウント移行

ユーザー数・チーム規模の拡大後、AWS Organizations を導入してアカウントレベルで環境を分離します。

```
AWS Organizations
├── Management Account   (請求・ガバナンス)
├── Dev Account          (開発環境)
├── Staging Account      (ステージング環境)
└── Production Account   (本番環境)
```
