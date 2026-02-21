# リポジトリ構成

## マルチリポジトリ戦略

OSS としてのアプリケーションコードと、企業管理のインフラ・商用機能を分離するオープンコアモデルを採用しています。

| リポジトリ | 公開範囲 | 役割 |
|---|---|---|
| `airas-org/airas` | Public (OSS) | アプリ本体（フロントエンド + バックエンド + プラグインインターフェース） |
| `NexaScience/airas-infra` | Private | Terraform、CI/CD、デプロイ設定 |

### OSS と商用機能の境界

| 機能 | OSS / 商用 | 理由 |
|---|---|---|
| 研究自動化コアエンジン | OSS | プロジェクトの核心的価値 |
| 実験機器プラグイン API | OSS | コミュニティ拡張の基盤 |
| 組み込み機器実装 | OSS | 参考実装として必須 |
| 認証・ユーザー管理 | 商用 | 運用コストがかかる |
| 課金・使用量制限 | 商用 | ビジネスロジック |
| エンタープライズ監視・SLA | 商用 | 付加価値サービス |

---

## airas-infra ディレクトリ構成

```
airas-infra/
├── .claude/                        # Claude Code 設定
├── .github/
│   └── workflows/
│       ├── deploy-backend.yml      # バックエンドデプロイ (ECR → ECS)
│       ├── deploy-frontend.yml     # フロントエンドデプロイ (S3 → CloudFront)
│       └── terraform-plan.yml      # Terraform plan/apply
├── docs/                           # ドキュメント
│   ├── plans/                      #   実装計画
│   ├── architecture.md             #   アーキテクチャ図
│   ├── infrastructure-details.md   #   インフラ詳細
│   ├── tech-stack.md               #   技術スタック一覧
│   ├── repository-structure.md     #   リポジトリ構成（本ファイル）
│   └── environments.md             #   環境説明
├── scripts/
│   └── bootstrap-backend.sh        # Terraform backend 初期セットアップ
├── terraform/
│   ├── modules/                    # 再利用可能な Terraform モジュール
│   │   ├── vpc/                    #   VPC, サブネット, NAT Gateway
│   │   ├── ecr/                    #   ECR リポジトリ
│   │   ├── ecs/                    #   ECS Cluster, Service, Task Definition
│   │   ├── rds/                    #   RDS PostgreSQL
│   │   ├── s3-cloudfront/          #   S3 + CloudFront
│   │   ├── monitoring/             #   CloudWatch
│   │   └── waf/                    #   WAF
│   ├── environments/
│   │   ├── dev/                    # 開発環境
│   │   ├── staging/                # ステージング環境
│   │   └── prod/                   # 本番環境
│   └── global/                     # 環境横断リソース (ECR, IAM)
├── .gitignore
└── README.md
```

### Terraform モジュール構成

各モジュールは `main.tf` / `variables.tf` / `outputs.tf` の 3 ファイル構成です。

| モジュール | 管理リソース |
|---|---|
| `vpc` | VPC, サブネット (Public/Private), NAT Gateway, ルートテーブル |
| `ecr` | ECR リポジトリ, ライフサイクルポリシー |
| `ecs` | ECS Cluster, Service, Task Definition, ALB, セキュリティグループ |
| `rds` | RDS PostgreSQL インスタンス, サブネットグループ, セキュリティグループ |
| `s3-cloudfront` | S3 バケット, CloudFront ディストリビューション, OAC |
| `monitoring` | CloudWatch ダッシュボード, アラーム, SNS トピック |
| `waf` | WAF Web ACL, マネージドルール |

### 環境ディレクトリ構成

各環境ディレクトリ (`dev` / `staging` / `prod`) は以下のファイルを持ちます:

```
environments/{env}/
├── backend.tf              # S3 リモートステート設定
├── providers.tf            # AWS プロバイダー設定
├── variables.tf            # 環境固有の変数定義
├── main.tf                 # モジュール呼び出し
├── outputs.tf              # 出力値
└── terraform.tfvars.example # 変数ファイルのサンプル
```

---

## ブランチ運用

```
feature/xxx → develop → main
                ↑          ↑
           開発統合      本番リリース
```

| ブランチ | 用途 | デプロイ先 |
|---|---|---|
| `feature/*` | 機能開発 | - |
| `develop` | 開発統合 | dev 環境 |
| `staging` | リリース準備 | staging 環境 |
| `main` | 本番リリース | production 環境 |
