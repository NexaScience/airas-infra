# AWS バックエンド削除設計

日付: 2026-03-01

## 背景

バックエンドを Railway に移行完了したため、AWS 上のバックエンド関連リソースをすべて削除する。
Route 53 の Hosted Zone と Vercel 向け frontend CNAME レコードのみ残す。

## 残存リソース

| リソース | 管理場所 | 目的 |
|---------|---------|------|
| Route 53 Hosted Zone (`airas.io`) | `terraform/global/` | DNS 管理の基盤 |
| CNAME: `app.airas.io` → `cname.vercel-dns.com` | `terraform/global/` に移動 | Vercel フロントエンド |
| CNAME: `app-dev.airas.io` → `cname.vercel-dns.com` | `terraform/global/` に移動 | Vercel フロントエンド (dev) |
| S3 state bucket + DynamoDB lock | 手動管理 | Terraform state (global 用に継続利用) |

## 削除対象

### AWS 実リソース

**dev 環境**: VPC, ECS, ALB, RDS, Secrets Manager, CloudWatch, NAT Gateway, DNS レコード (api-dev), ACM 証明書
**prod 環境**: VPC, ECS, ALB, RDS, WAF, Secrets Manager, CloudWatch, NAT Gateway, DNS レコード (api), ACM 証明書
**global**: ECR リポジトリ

### Terraform コード

- `terraform/environments/dev/` — 全ファイル削除
- `terraform/environments/prod/` — 全ファイル削除
- `terraform/modules/vpc/`, `ecs/`, `rds/`, `dns/`, `waf/`, `monitoring/`, `secrets/`, `ecr/` — 全削除

### GitHub Actions ワークフロー

- `.github/workflows/terraform-apply.yml`
- `.github/workflows/terraform-plan.yml`
- `.github/workflows/sync-secrets.yml`

## 実行手順

1. frontend CNAME を `terraform/global/main.tf` に移動
2. global を `terraform apply` — CNAME が global 管理になる
3. dev 環境を `terraform destroy`
4. prod の RDS `deletion_protection` を `false` に変更 → apply
5. prod 環境を `terraform destroy`
6. global から ECR を削除 (コード変更 → apply)
7. Terraform コード・モジュール・ワークフロー削除
8. ドキュメント更新

## 注意事項

- prod RDS は `deletion_protection = true` → destroy 前に解除が必要
- prod RDS は `skip_final_snapshot = false` → 最終スナップショット自動作成
- API DNS レコードは Railway 側で設定済みのため削除による影響なし

## アプローチ

一括削除方式を採用。
