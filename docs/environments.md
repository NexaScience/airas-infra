# 環境構成 (dev / prod)

## 概要

2 つの環境を Terraform の環境別ディレクトリで管理しています。フロントエンドは Vercel でホスティングしており、Terraform 管理外です。

```
単一 AWS アカウント (427979936961)
├── dev      (ECS: airas-dev-*,     RDS: airas-dev)
└── prod     (ECS: airas-prod-*,    RDS: airas-prod)

フロントエンド: Vercel (Terraform 管理外)
```

---

## dev（開発環境）

開発者が機能開発・テストを行うための環境です。コスト最小構成で運用します。

| 項目 | 設定 |
|---|---|
| **デプロイトリガー** | `develop` ブランチへの push |
| **VPC CIDR** | 10.0.0.0/16 |

### リソーススペック

| リソース | スペック |
|---|---|
| ECS Fargate | 0.25 vCPU / 512 MB / 1 タスク / Auto Scaling なし |
| RDS | db.t3.small / 20 GB / Single-AZ / バックアップ 7 日 / 削除保護なし |
| NAT Gateway | 1（シングル AZ） |
| WAF | なし |
| ログ保持 | 7 日 |

### 月額コスト概算: ~$90

---

## prod（本番環境）

エンドユーザーに提供する本番環境です。高可用性・セキュリティ・監視を強化しています。

| 項目 | 設定 |
|---|---|
| **デプロイトリガー** | `main` ブランチへの push（承認ゲート付き） |
| **VPC CIDR** | 10.2.0.0/16 |

### リソーススペック

| リソース | スペック |
|---|---|
| ECS Fargate | 1 vCPU / 2048 MB / 最小 2 タスク / Auto Scaling 2-4（CPU 70% ターゲット） |
| RDS | db.r6g.large / 50 GB / **Multi-AZ** / バックアップ 30 日 / **削除保護あり** |
| NAT Gateway | **2（冗長構成）** |
| WAF | **有効**（AWS Managed Rules + レートリミット） |
| ログ保持 | 90 日 |

### 月額コスト概算: ~$240

---

## 環境比較表

| | dev | prod |
|--|-----|------|
| **VPC CIDR** | 10.0.0.0/16 | 10.2.0.0/16 |
| **ECS CPU** | 256 | 1024 |
| **ECS メモリ** | 512 MB | 2048 MB |
| **ECS タスク数** | 1 | 2-4 |
| **Auto Scaling** | なし | CPU 70% ターゲット |
| **RDS インスタンス** | db.t3.small | db.r6g.large |
| **RDS ストレージ** | 20 GB | 50 GB |
| **Multi-AZ** | No | Yes |
| **バックアップ保持** | 7 日 | 30 日 |
| **削除保護** | No | Yes |
| **NAT Gateway** | 1 | 2 |
| **WAF** | なし | あり |
| **ログ保持** | 7 日 | 90 日 |
| **デプロイ** | 自動 | 承認ゲート付き |
| **フロントエンド** | Vercel | Vercel |

---

## ドメイン・DNS

Route 53 で管理（ドメイン取得後に有効化）:

```
api.airas.example.com      → ALB (バックエンド API)
```

フロントエンドのドメインは Vercel 側で管理します。

---

## 将来計画: マルチアカウント移行

ユーザー数・チーム規模の拡大後、AWS Organizations を導入してアカウントレベルで環境を分離します。

```
AWS Organizations
├── Management Account   (請求・ガバナンス)
├── Dev Account          (開発環境)
└── Production Account   (本番環境)
```
