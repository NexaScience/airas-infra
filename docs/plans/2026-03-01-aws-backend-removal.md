# AWS バックエンド削除 実装計画

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** バックエンド Railway 移行に伴い、AWS 上のバックエンドリソースを全削除し、Route 53 (Hosted Zone + Vercel CNAME) のみ残す

**Architecture:** frontend CNAME を global に移動してから dev/prod 環境を destroy し、最後に ECR を削除してコードを整理する。Terraform state backend (S3/DynamoDB) は global 管理用に残す。

**Tech Stack:** Terraform, AWS CLI, GitHub Actions

---

### Task 1: frontend CNAME レコードを global に移動

**Files:**
- Modify: `terraform/global/main.tf`
- Modify: `terraform/global/outputs.tf`
- Modify: `terraform/global/variables.tf`

**Step 1: `terraform/global/main.tf` に frontend CNAME レコードを追加**

ECR モジュール呼び出しの下に以下を追加:

```hcl
################################################################################
# DNS Records: Frontend subdomains → Vercel
################################################################################

resource "aws_route53_record" "frontend_prod" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["cname.vercel-dns.com"]
}

resource "aws_route53_record" "frontend_dev" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app-dev.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["cname.vercel-dns.com"]
}
```

**Step 2: `terraform/global/outputs.tf` に frontend FQDN output を追加**

```hcl
output "frontend_prod_fqdn" {
  description = "Frontend prod domain name"
  value       = aws_route53_record.frontend_prod.fqdn
}

output "frontend_dev_fqdn" {
  description = "Frontend dev domain name"
  value       = aws_route53_record.frontend_dev.fqdn
}
```

**Step 3: global の state に既存 CNAME レコードを import**

DNS レコードが dev/prod 環境の state で管理されているため、global に import して二重管理を防ぐ。

```bash
cd terraform/global
terraform init
terraform import 'aws_route53_record.frontend_prod' '<ZONE_ID>_app.airas.io_CNAME'
terraform import 'aws_route53_record.frontend_dev' '<ZONE_ID>_app-dev.airas.io_CNAME'
```

> **注意:** `<ZONE_ID>` は `terraform output route53_zone_id` で取得。import ID の形式は `{zone_id}_{name}_{type}`。

**Step 4: `terraform plan` で差分なしを確認**

```bash
terraform plan
```

Expected: `No changes. Your infrastructure matches the configuration.` (または CNAME 値のみの軽微な差分)

**Step 5: `terraform apply` で確定**

```bash
terraform apply
```

**Step 6: コミット**

```bash
git add terraform/global/main.tf terraform/global/outputs.tf
git commit -m "feat: frontend CNAME レコードを global に移動"
```

---

### Task 2: dev 環境の terraform destroy

**Files:**
- 対象: `terraform/environments/dev/`

**Step 1: dev 環境の state から frontend CNAME を除外**

frontend CNAME は global で管理するため、dev の state から除外する:

```bash
cd terraform/environments/dev
terraform init
terraform state rm 'module.dns.aws_route53_record.frontend'
```

**Step 2: terraform plan -destroy で削除対象を確認**

```bash
terraform plan -destroy
```

Expected: VPC, ECS, ALB, RDS, Secrets Manager, CloudWatch, NAT Gateway, API DNS レコード, ACM 証明書が削除対象として表示される。frontend CNAME は含まれないこと。

**Step 3: terraform destroy を実行**

```bash
terraform destroy
```

確認プロンプトで `yes` を入力。

Expected: 全リソースが正常に削除される。

---

### Task 3: prod 環境の terraform destroy

**Files:**
- Modify: `terraform/environments/prod/main.tf` (一時的に deletion_protection 解除)

**Step 1: prod の state から frontend CNAME を除外**

```bash
cd terraform/environments/prod
terraform init
terraform state rm 'module.dns.aws_route53_record.frontend'
```

**Step 2: RDS の deletion_protection を false に変更**

`terraform/environments/prod/main.tf` の `module "rds"` ブロック:

```hcl
  deletion_protection     = false
  skip_final_snapshot     = true
```

**Step 3: apply して deletion_protection を解除**

```bash
terraform apply
```

**Step 4: terraform plan -destroy で削除対象を確認**

```bash
terraform plan -destroy
```

Expected: VPC, ECS, ALB, RDS, WAF, Secrets Manager, CloudWatch, NAT Gateway, API DNS レコード, ACM 証明書が削除対象として表示される。

**Step 5: terraform destroy を実行**

```bash
terraform destroy
```

確認プロンプトで `yes` を入力。

Expected: 全リソースが正常に削除される。

---

### Task 4: global から ECR を削除

**Files:**
- Modify: `terraform/global/main.tf`
- Modify: `terraform/global/outputs.tf`

**Step 1: `terraform/global/main.tf` から ECR モジュール呼び出しを削除**

以下のブロックを削除:

```hcl
module "ecr" {
  source = "../modules/ecr"

  project = var.project
}
```

**Step 2: `terraform/global/outputs.tf` から ECR outputs を削除**

以下を削除:

```hcl
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = module.ecr.repository_arn
}
```

**Step 3: terraform apply で ECR を削除**

```bash
cd terraform/global
terraform apply
```

Expected: ECR リポジトリが削除される。

**Step 4: コミット**

```bash
git add terraform/global/main.tf terraform/global/outputs.tf
git commit -m "feat: global から ECR リポジトリを削除"
```

---

### Task 5: 不要な Terraform コードを削除

**Files:**
- Delete: `terraform/environments/dev/` (ディレクトリ全体)
- Delete: `terraform/environments/prod/` (ディレクトリ全体)
- Delete: `terraform/modules/vpc/` (ディレクトリ全体)
- Delete: `terraform/modules/ecs/` (ディレクトリ全体)
- Delete: `terraform/modules/rds/` (ディレクトリ全体)
- Delete: `terraform/modules/dns/` (ディレクトリ全体)
- Delete: `terraform/modules/waf/` (ディレクトリ全体)
- Delete: `terraform/modules/monitoring/` (ディレクトリ全体)
- Delete: `terraform/modules/secrets/` (ディレクトリ全体)
- Delete: `terraform/modules/ecr/` (ディレクトリ全体)

**Step 1: environments ディレクトリを削除**

```bash
rm -rf terraform/environments/dev terraform/environments/prod
```

**Step 2: 不要なモジュールを削除**

```bash
rm -rf terraform/modules/vpc terraform/modules/ecs terraform/modules/rds \
       terraform/modules/dns terraform/modules/waf terraform/modules/monitoring \
       terraform/modules/secrets terraform/modules/ecr
```

**Step 3: environments ディレクトリが空なら削除**

```bash
rmdir terraform/environments 2>/dev/null || true
rmdir terraform/modules 2>/dev/null || true
```

**Step 4: コミット**

```bash
git add -A terraform/environments terraform/modules
git commit -m "feat: 不要な Terraform environments と modules を削除"
```

---

### Task 6: GitHub Actions ワークフローとスクリプトを削除

**Files:**
- Delete: `.github/workflows/terraform-apply.yml`
- Delete: `.github/workflows/terraform-plan.yml`
- Delete: `.github/workflows/sync-secrets.yml`
- Delete: `scripts/bootstrap-backend.sh`
- Delete: `scripts/install-aws-cli.sh`

**Step 1: ワークフローファイルを削除**

```bash
rm .github/workflows/terraform-apply.yml \
   .github/workflows/terraform-plan.yml \
   .github/workflows/sync-secrets.yml
```

**Step 2: 不要なスクリプトを削除**

```bash
rm scripts/bootstrap-backend.sh scripts/install-aws-cli.sh
rmdir scripts 2>/dev/null || true
```

**Step 3: .github/workflows が空なら削除**

```bash
rmdir .github/workflows 2>/dev/null || true
rmdir .github 2>/dev/null || true
```

**Step 4: コミット**

```bash
git add -A .github/workflows scripts
git commit -m "feat: 不要な GitHub Actions ワークフローとスクリプトを削除"
```

---

### Task 7: ドキュメントを更新

**Files:**
- Modify: `docs/architecture.md`
- Modify: `docs/tech-stack.md`
- Modify: `docs/environments.md`
- Modify: `docs/infrastructure-details.md`
- Modify: `docs/repository-structure.md`

**Step 1: 各ドキュメントを Railway 移行後の構成に更新**

主な変更点:
- AWS バックエンド (ECS, RDS, VPC 等) の記述を削除
- Railway でバックエンドをホスティングしている旨に更新
- 残存 AWS リソース (Route 53, S3 state) のみの記述に整理
- コスト見積もりの更新 (Route 53 のみ: ~$1/月)

**Step 2: コミット**

```bash
git add docs/
git commit -m "docs: AWS バックエンド削除に伴うドキュメント更新"
```

---

### Task 8: 最終確認

**Step 1: global の terraform plan が差分なしであることを確認**

```bash
cd terraform/global
terraform plan
```

Expected: `No changes.`

**Step 2: リポジトリ構造の最終確認**

残存すべきファイル:
```
terraform/
  global/
    main.tf          # Route 53 Hosted Zone + frontend CNAME
    backend.tf       # S3 state backend
    providers.tf     # AWS provider
    variables.tf     # project, aws_region, domain_name
    outputs.tf       # zone_id, name_servers, frontend FQDNs
```

**Step 3: コミット (もし追加変更があれば)**

```bash
git add -A
git commit -m "chore: AWS バックエンド削除の最終整理"
```
