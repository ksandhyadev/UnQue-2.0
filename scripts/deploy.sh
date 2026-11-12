#!/usr/bin/env bash
# =============================================================
#  deploy.sh  —  Zero-downtime redeploy (run on EC2 after ec2-setup.sh)
#
#  Usage:
#    ssh -i <key>.pem ec2-user@<EC2-IP> "bash ~/unque-api/scripts/deploy.sh"
# =============================================================
set -euo pipefail

APP_DIR="/home/ec2-user/unque-api"

echo "[deploy] Pulling latest changes..."
cd "$APP_DIR"
git pull

echo "[deploy] Installing / updating dependencies..."
npm ci --omit=dev

echo "[deploy] Reloading PM2 (zero-downtime)..."
pm2 reload unque-api --update-env

echo "[deploy] Done — $(pm2 jlist | python3 -c 'import sys,json; a=json.load(sys.stdin); [print(f\"  {p[\"name\"]}  pid={p[\"pid\"]}  status={p[\"pm2_env\"][\"status\"]}\") for p in a]')"
