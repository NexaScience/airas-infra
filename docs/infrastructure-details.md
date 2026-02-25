# インフラ詳細

## コンピュート

### ECS Fargate (バックエンド)

FastAPI アプリケーションを Docker コンテナとして ECS Fargate 上で実行します。

| 項目 | 詳細 |
|---|---|
| 選定理由 | 既存 Dockerfile をそのまま利用可能。長時間実行タスクに対応（Lambda は 15 分制限で不可） |
| ロードバランサー | ALB |
| コンテナレジストリ | Amazon ECR |
| ヘルスチェック | `/health` エンドポイント |

#### 環境別スペック

| | dev | prod |
|--|-----|------|
| CPU | 256 (0.25 vCPU) | 1024 (1 vCPU) |
| メモリ | 512 MB | 2048 MB |
| 最小タスク数 | 1 | 2 |
| 最大タスク数 | 2 | 4 |
| Auto Scaling | なし | CPU 70% ターゲット (2-4) |

#### 長時間実行タスクの対応

現在 `asyncio.create_task()` でプロセス内実行のため、段階的に分離予定:

1. **短期**: ALB ドレイン時間を十分長く設定
2. **中期（推奨）**: Celery + Redis を導入し、Worker サービスに分離
3. **長期**: AWS Step Functions との統合も検討

---

## フロントエンドホスティング

### Vercel

フロントエンド（React SPA）は Vercel でホスティングしています。Terraform 管理外です。

| 項目 | 詳細 |
|---|---|
| ホスティング | Vercel |
| フレームワーク | React (Vite) |
| デプロイ | Git push による自動デプロイ |
| 管理 | Terraform 管理外 |

---

## データベース・ストレージ

### RDS PostgreSQL 16

| | dev | prod |
|--|-----|------|
| インスタンス | db.t3.small | db.r6g.large |
| ストレージ | 20 GB | 50 GB |
| Multi-AZ | No | Yes |
| バックアップ保持 | 7 日 | 30 日 |
| 削除保護 | No | Yes |

### その他ストレージ

| 用途 | サービス | 備考 |
|---|---|---|
| キャッシュ/タスクキュー | ElastiCache for Redis | Celery 導入時に追加 |
| ファイルストレージ | S3 | 生成された LaTeX/PDF 等 |
| ベクトル DB | 外部 Qdrant（現状維持） | 移行優先度は低い |

---

## ネットワーク

### VPC

| | dev | prod |
|--|-----|------|
| VPC CIDR | 10.0.0.0/16 | 10.2.0.0/16 |
| Public Subnet | 2 (ALB, NAT GW) | 2 |
| Private Subnet | 2 (ECS, RDS) | 2 |
| NAT Gateway | 1 | 2 (冗長構成) |
| AZ | 2 | 2 |

---

## セキュリティ

| 項目 | 方針 |
|---|---|
| IAM | 最小権限の原則。ECS Task Role / Execution Role を分離 |
| CI/CD 認証 | GitHub Actions OIDC（長期アクセスキー不使用） |
| WAF | AWS Managed Rules + レートリミット（prod の ALB にアタッチ） |
| SSL/TLS | ACM で無料証明書、自動更新 |
| Shield | Standard（自動適用、追加コスト無し） |

### シークレット管理

| シークレット | 格納先 |
|---|---|
| DATABASE_URL | Secrets Manager（自動ローテーション対応） |
| OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY 等 | Secrets Manager |
| GH_PERSONAL_ACCESS_TOKEN | Secrets Manager |
| AWS_BEARER_TOKEN_BEDROCK | 不要（IAM ロールで代替） |
| LANGFUSE_*, WANDB_API_KEY | Parameter Store (SecureString) |

ECS タスク定義の `secrets` プロパティで環境変数に注入。コンテナイメージにシークレットは含めません。

---

## 監視・ログ

### ログ

| 対象 | 設定 |
|---|---|
| ECS コンテナログ | CloudWatch Logs（保持: dev 7 日 / prod 90 日） |
| ALB アクセスログ | S3 に保存 |
| RDS ログ | slow query log, error log → CloudWatch Logs |
| CloudTrail | 全リージョン有効化（API 呼び出し監査） |

### アラーム

| メトリクス | 閾値 | アクション |
|---|---|---|
| ECS CPU 使用率 | > 80%（5 分間） | SNS → Discord 通知 |
| ECS メモリ使用率 | > 85%（5 分間） | SNS → Discord 通知 |
| RDS CPU 使用率 | > 70%（10 分間） | SNS → Discord 通知 |
| RDS 空きストレージ | < 5GB | SNS → Discord 通知 |
| ALB 5xx エラー率 | > 5%（5 分間） | SNS → Discord 通知 |

### トレーシング

- LLM 可観測性: Langfuse（既存活用）
- フロントエンドエラー: Sentry
- コンテナメトリクス: CloudWatch Container Insights

---

## Terraform State 管理

| リソース | 値 |
|---|---|
| S3 バケット | airas-terraform-state-427979936961 |
| DynamoDB テーブル | airas-terraform-lock |
| リージョン | ap-northeast-1 |

各環境の state パス: `global/terraform.tfstate`, `{env}/terraform.tfstate`

---

## コスト見積もり

### dev 環境（最小構成）

| サービス | 構成 | 月額概算 |
|---|---|---|
| ECS Fargate | 0.25 vCPU, 512MB RAM x 1 タスク | ~$10 |
| RDS PostgreSQL | db.t3.small, 20GB | ~$15 |
| ALB | 1 ALB | ~$20 |
| NAT Gateway | 1 AZ | ~$35 |
| Secrets Manager | ~10 シークレット | ~$4 |
| CloudWatch Logs | 最小 | ~$5 |
| Route 53 | 1 ホストゾーン | ~$1 |
| **合計** | | **~$90/月** |

### production（中規模トラフィック）

| サービス | 構成 | 月額概算 |
|---|---|---|
| ECS Fargate | 1 vCPU, 2GB RAM x 2 タスク | ~$60 |
| RDS PostgreSQL | db.r6g.large, 50GB, マルチ AZ | ~$50 |
| ALB | 1 ALB | ~$25 |
| NAT Gateway | 2 AZ | ~$70 |
| WAF | Web ACL + ルール | ~$10 |
| Secrets Manager | ~10 シークレット | ~$4 |
| CloudWatch | ログ + アラーム | ~$20 |
| Route 53 | 1 ホストゾーン + ヘルスチェック | ~$2 |
| **合計** | | **~$240/月** |

### コスト削減策

- **NAT Gateway 代替**: dev 環境では fck-nat（OSS の NAT インスタンス）で $35/月削減
- **Savings Plans**: 本番安定後に Compute Savings Plans（1 年）で Fargate コスト最大 50% 削減
- **RDS Reserved Instance**: 本番 RDS を 1 年 RI で約 40% 削減
- **ECS スケジュールスケーリング**: dev は夜間・休日にタスク数 0
