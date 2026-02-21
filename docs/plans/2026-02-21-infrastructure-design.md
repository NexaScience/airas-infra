# AIRAS Infrastructure Design

## Overview

AWS infrastructure for the AIRAS project, managed with Terraform.

- **Region**: ap-northeast-1 (Tokyo)
- **Environments**: dev, staging, prod
- **Backend**: FastAPI (Python) on ECS Fargate
- **Frontend**: React (Vite) on S3 + CloudFront
- **Database**: RDS PostgreSQL 16
- **Domain**: To be acquired later (placeholder in config)
- **AWS Account**: 427979936961

## Directory Structure

```
terraform/
├── modules/
│   ├── vpc/
│   ├── ecr/
│   ├── ecs/
│   ├── rds/
│   ├── s3-cloudfront/
│   ├── secrets/
│   ├── dns/
│   ├── monitoring/
│   └── waf/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
└── global/
```

- Each environment has independent state files
- `global/` holds cross-environment resources (ECR, IAM)
- State stored in S3 with DynamoDB locking

## Terraform Backend

| Resource | Value |
|----------|-------|
| S3 Bucket | airas-terraform-state-427979936961 |
| DynamoDB Table | airas-terraform-lock |
| Region | ap-northeast-1 |

State paths: `global/terraform.tfstate`, `{env}/terraform.tfstate`

## Network (VPC)

| | dev | staging | prod |
|--|-----|---------|------|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| Public Subnets | 2 (ALB, NAT GW) | 2 | 2 |
| Private Subnets | 2 (ECS, RDS) | 2 | 2 |
| NAT Gateway | 1 | 1 | 2 (redundant) |
| AZs | 2 | 2 | 2 |

## Compute (ECS Fargate)

| | dev | staging | prod |
|--|-----|---------|------|
| CPU | 256 | 512 | 1024 |
| Memory | 512 MB | 1024 MB | 2048 MB |
| Tasks | 1 | 1 | 2 (min) |
| Auto Scaling | No | No | 2-4 |
| ALB | Yes | Yes | Yes |
| Health Check | /health | /health | /health |

## Database (RDS PostgreSQL)

| | dev | staging | prod |
|--|-----|---------|------|
| Instance | db.t3.small | db.t3.small | db.r6g.large |
| Storage | 20 GB | 20 GB | 50 GB |
| Multi-AZ | No | No | Yes |
| Backup Retention | 7 days | 7 days | 30 days |
| Deletion Protection | No | No | Yes |

## Frontend (S3 + CloudFront)

- S3 bucket: `airas-{env}-frontend`
- CloudFront with OAC for S3 access
- SPA routing: 404 -> index.html
- WAF on prod only

## Additional Services

- **Secrets Manager**: RDS passwords, API keys
- **Route 53 + ACM**: Enabled after domain acquisition
- **CloudWatch**: CPU/memory, RDS connections, ALB 5xx alarms
- **WAF**: Prod CloudFront + ALB (rate limit, SQLi/XSS protection)

## Implementation Phases

1. Terraform backend (S3 + DynamoDB) + directory structure
2. VPC + networking
3. ECR + ECS Fargate + ALB
4. RDS PostgreSQL
5. S3 + CloudFront
6. Secrets Manager
7. Route 53 + ACM (after domain)
8. CI/CD pipeline
9. CloudWatch monitoring
10. WAF
