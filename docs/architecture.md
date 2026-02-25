# アーキテクチャ

## 全体構成図

```mermaid
graph TB
    User["ユーザー"]

    subgraph Vercel["Vercel (Terraform 管理外)"]
        Frontend["React SPA\n(フロントエンド)"]
    end

    subgraph AWS["AWS Cloud (ap-northeast-1)"]
        Route53["Route 53"]
        WAF["WAF (staging/prod)"]

        subgraph VPC["VPC (10.x.0.0/16)"]
            subgraph Public["Public Subnet (x2 AZ)"]
                ALB["ALB"]
                NAT["NAT Gateway"]
            end
            subgraph PrivateApp["Private Subnet (x2 AZ) - App"]
                ECS["ECS Fargate\n(FastAPI)"]
            end
            subgraph PrivateDB["Private Subnet (x2 AZ) - DB"]
                RDS["RDS PostgreSQL 16"]
            end
        end

        SecretsManager["Secrets Manager"]
        CloudWatch["CloudWatch\n(監視)"]
    end

    subgraph External["外部サービス"]
        LLM["OpenAI / Anthropic\nGoogle Gemini"]
        GitHub["GitHub API"]
        Qdrant["Qdrant\n(ベクトルDB)"]
        WandB["W&B\n(実験追跡)"]
        Langfuse["Langfuse\n(LLM 可観測性)"]
        Academic["Semantic Scholar\narXiv / OpenAlex"]
    end

    User -->|HTTPS| Vercel
    User -->|HTTPS| Route53
    Route53 --> WAF
    WAF --> ALB
    ALB --> ECS
    ECS --> RDS
    ECS --> NAT
    NAT --> External
    ECS -.-> SecretsManager
    ECS -.-> CloudWatch
```

## リクエストフロー

```
ユーザー
  │
  ├── フロントエンド ──▶ Vercel (React SPA)
  │                        │
  │                        ▼
  └── API リクエスト ──▶ Route 53 (DNS)
                          │
                          ▼
                      WAF (prod のみ)
                          │
                          ▼
                      ALB (HTTPS)
                          │
                          ▼
                      ECS Fargate (FastAPI)
                          │
                          ▼
                      RDS PostgreSQL (Private Subnet)
```

## CI/CD パイプライン

```mermaid
graph LR
    subgraph GHA["GitHub Actions (OIDC → IAM Role)"]
        subgraph Backend["Backend Deploy"]
            B1["Docker build"] --> B2["ECR push"] --> B3["ECS service\nupdate"]
        end
        subgraph Infra["Terraform"]
            T1["plan"] --> T2["apply"]
        end
    end

    subgraph VercelDeploy["Vercel"]
        V1["Git push"] --> V2["自動ビルド\n& デプロイ"]
    end

    subgraph Trigger["デプロイフロー"]
        Dev["develop push\n→ dev 自動デプロイ"]
        Staging["workflow_dispatch\n→ staging 手動デプロイ"]
        Prod["main push\n→ prod デプロイ\n(承認ゲート付き)"]
    end

    Trigger --> GHA
    Trigger --> VercelDeploy
```

## ネットワーク設計

```
VPC (10.x.0.0/16)     ※ x = 0(dev), 1(staging), 2(prod)
│
├── Public Subnet x2 (10.x.1.0/24, 10.x.2.0/24) - 2AZ
│   ├── ALB
│   └── NAT Gateway
│
├── Private Subnet x2 (10.x.10.0/24, 10.x.11.0/24) - 2AZ
│   └── ECS Fargate (バックエンド)
│
└── Private Subnet x2 (10.x.20.0/24, 10.x.21.0/24) - 2AZ
    └── RDS PostgreSQL
```

## セキュリティグループ

| SG | インバウンド | アウトバウンド |
|---|---|---|
| ALB SG | 443 (0.0.0.0/0) | ECS SG:8000 |
| ECS Backend SG | 8000 (ALB SG) | RDS SG:5432, 443 (外部API) |
| RDS SG | 5432 (ECS Backend SG) | なし |
