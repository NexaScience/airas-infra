#!/bin/bash
set -euo pipefail

echo "=== AWS CLI v2 インストールスクリプト ==="

# 既にインストール済みの場合はスキップ
if command -v aws &>/dev/null; then
  echo "AWS CLI は既にインストールされています: $(aws --version)"
  exit 0
fi

# アーキテクチャの判定
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" ;;
  aarch64) URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" ;;
  *)       echo "未対応のアーキテクチャ: $ARCH"; exit 1 ;;
esac

# 1. 必要なツールの確認
echo "[1/4] 依存ツールの確認..."
for cmd in curl unzip; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "  $cmd が見つかりません。インストールします..."
    apt-get update -qq && apt-get install -y -qq "$cmd"
  else
    echo "  $cmd ... OK"
  fi
done

# 2. AWS CLI v2 のダウンロード
echo "[2/4] AWS CLI v2 をダウンロード中... ($ARCH)"
TMPDIR=$(mktemp -d)
curl -fsSL "$URL" -o "$TMPDIR/awscliv2.zip"

# 3. 解凍 & インストール
echo "[3/4] インストール中..."
unzip -q "$TMPDIR/awscliv2.zip" -d "$TMPDIR"
"$TMPDIR/aws/install"

# 4. クリーンアップ & 確認
echo "[4/4] クリーンアップ..."
rm -rf "$TMPDIR"

echo ""
echo "=== インストール完了 ==="
aws --version
