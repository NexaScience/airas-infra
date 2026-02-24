# 技術スタック一覧

## インフラ基盤

| カテゴリ | 技術 | 用途 |
|---|---|---|
| クラウド | AWS | メインクラウドプラットフォーム |
| リージョン | ap-northeast-1 (東京) | プライマリリージョン |
| IaC | Terraform >= 1.6 | インフラのコード管理 |
| CI/CD | GitHub Actions | ビルド・デプロイ自動化 |
| 認証連携 | OIDC (GitHub → AWS) | CI/CD からの AWS 認証 |

## AWS サービス

### コンピュート・ネットワーク

| サービス | 用途 |
|---|---|
| ECS Fargate | バックエンドコンテナ実行 |
| ECR | Docker イメージレジストリ |
| ALB | ロードバランサー |
| VPC | ネットワーク分離 |
| NAT Gateway | プライベートサブネットからの外部通信 |
| Route 53 | DNS 管理 |
| CloudFront | CDN（フロントエンド + API キャッシュ） |

### データ・ストレージ

| サービス | 用途 |
|---|---|
| RDS PostgreSQL 16 | メインデータベース |
| S3 | フロントエンドホスティング / ファイルストレージ / ログ保存 |
| ElastiCache for Redis | キャッシュ / タスクキュー（Celery 導入時） |

### セキュリティ

| サービス | 用途 |
|---|---|
| IAM | アクセス制御 |
| Secrets Manager | DB パスワード / API キー管理 |
| Parameter Store | Langfuse / W&B 等の設定値 |
| ACM | SSL/TLS 証明書（自動更新） |
| WAF | Web アプリケーションファイアウォール（staging / prod） |
| Shield Standard | DDoS 防御 |

### 監視・運用

| サービス | 用途 |
|---|---|
| CloudWatch Logs | コンテナ / RDS / ALB ログ収集 |
| CloudWatch Alarms | メトリクスベースのアラート |
| CloudWatch Container Insights | ECS メトリクス |
| CloudWatch RUM | フロントエンドパフォーマンス |
| CloudTrail | API 呼び出し監査 |
| SNS | アラーム通知 → Discord |

## アプリケーション

### フロントエンド

| 項目 | 技術 |
|---|---|
| フレームワーク | React 19 (SPA) |
| ビルドツール | Vite 7 |
| 言語 | TypeScript 5.9 |
| UI ライブラリ | Radix UI + Tailwind CSS 4 + shadcn/ui 系 |
| エラー追跡 | Sentry |

### バックエンド

| 項目 | 技術 |
|---|---|
| フレームワーク | FastAPI (uvicorn) |
| 言語 | Python 3.11 |
| パッケージ管理 | uv + hatchling |
| ORM | SQLModel + SQLAlchemy + Alembic |
| AI/ML | LangChain, LangGraph, LiteLLM |
| LLM 可観測性 | Langfuse |
| 実験追跡 | Weights & Biases (W&B) |

## 外部サービス連携

| サービス | 用途 |
|---|---|
| OpenAI / Anthropic / Google Gemini | LLM API |
| GitHub API | リポジトリ連携 |
| Qdrant | ベクトル DB |
| Semantic Scholar / arXiv / OpenAlex | 学術論文検索 |
