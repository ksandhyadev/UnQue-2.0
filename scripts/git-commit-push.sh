#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/.."

git add -A
git commit -m "feat: add interactive browser dashboard UI at / to test all 10 API steps"
git push origin main
