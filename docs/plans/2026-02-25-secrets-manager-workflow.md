# Secrets Manager Workflow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** GitHub Secrets → GitHub Actions → AWS Secrets Manager → ECS コンテナ環境変数のパイプラインを構築する

**Architecture:** Terraformで Secrets Manager の「箱」を作成（値は管理外）、GitHub Actions ワークフローで値を同期、ECS タスク定義で secrets ブロックにより環境変数として注入

**Tech Stack:** Terraform (AWS Provider), GitHub Actions, AWS Secrets Manager, ECS Fargate

---

### Task 1: secrets モジュール作成

**Files:**
- Create: `terraform/modules/secrets/main.tf`
- Create: `terraform/modules/secrets/variables.tf`
- Create: `terraform/modules/secrets/outputs.tf`

13個のシークレットリソースを `for_each` で作成。`lifecycle { ignore_changes = [secret_string] }` で値を Terraform 管理外にする。

### Task 2: RDS モジュール修正 - DATABASE_URL 追加

**Files:**
- Modify: `terraform/modules/rds/main.tf`

既存の db-password シークレットの JSON に `database_url` フィールドを追加。ECS から直接参照可能にする。

### Task 3: ECS モジュール修正 - シークレット注入

**Files:**
- Modify: `terraform/modules/ecs/main.tf`
- Modify: `terraform/modules/ecs/variables.tf`
- Modify: `terraform/modules/ecs/outputs.tf`

コンテナ定義に `secrets` ブロックを追加。ECS 実行ロールに Secrets Manager 読み取り権限を付与。

### Task 4: 環境設定更新

**Files:**
- Modify: `terraform/environments/dev/main.tf`
- Modify: `terraform/environments/prod/main.tf`

secrets モジュールの呼び出しを追加し、出力を ECS モジュールに渡す。

### Task 5: GitHub Actions ワークフロー作成

**Files:**
- Create: `.github/workflows/sync-secrets.yml`

GitHub Secrets → AWS Secrets Manager に値を同期するワークフロー。手動実行（workflow_dispatch）で環境選択可能。

### Task 6: コミット

すべての変更をコミット。
