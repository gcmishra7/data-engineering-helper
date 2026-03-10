#!/usr/bin/env bash
# ============================================================
# push.sh — push data-engineering-helper to GitHub
# Usage: bash push.sh <YOUR_GITHUB_TOKEN>
#
# Before running:
#   1. Create the repo at https://github.com/new
#      Name: data-engineering-helper  (must match below)
#      Visibility: Public or Private
#      Do NOT initialise with README (leave it empty)
#   2. Run: bash push.sh ghp_yourTokenHere
# ============================================================

set -e

TOKEN="$1"
REPO="gcmishra7/data-engineering-helper"
REMOTE="https://${TOKEN}@github.com/${REPO}.git"

if [ -z "$TOKEN" ]; then
  echo "Usage: bash push.sh <YOUR_GITHUB_PERSONAL_ACCESS_TOKEN>"
  echo ""
  echo "Get a token at: https://github.com/settings/tokens"
  echo "Required scopes: repo (full control)"
  exit 1
fi

echo "Setting remote..."
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE"

echo "Adding all files..."
git add -A

echo "Committing..."
git commit -m "Initial commit: data-engineering-handbook v1

45 files across 10 chapters:
- 00-foundations (6 files)
- 01-data-modeling: relational, Kimball, Data Vault, medallion, dbt (7 files)
- 02-streaming-fundamentals: core concepts, Kafka, CDC (6 files)
- 03-governance: generic, Unity Catalog, Snowflake RBAC, lineage (5 files)
- 04-data-quality: dimensions, framework, DLT expectations, Snowflake DMFs (4 files)
- 05-databricks: Delta Lake, Spark, Structured Streaming, DLT (4 files)
- 06-snowflake: architecture, micro-partitions, clustering (2 files)
- 07-ecosystem-tools: Airflow, dbt, Great Expectations (1 file)
- 08-cloud-platforms: Azure, AWS, GCP (3 files)
- 09-cross-platform: table formats, Databricks+Snowflake bridge (2 files)
- 10-scenarios: fintech pipeline, retail lakehouse (2 files)" 2>/dev/null || echo "Nothing new to commit, proceeding with push..."

echo "Pushing to GitHub..."
git push -u origin main --force

echo ""
echo "✅ Done! View your repo at: https://github.com/${REPO}"
