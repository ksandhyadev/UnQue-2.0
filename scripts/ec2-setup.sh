#!/usr/bin/env bash
# =============================================================
#  ec2-setup.sh
#  Run this script ONCE on a fresh Amazon Linux 2023 / Ubuntu
#  EC2 instance to install Node 20, PM2, and deploy UnQue 2.0.
#
#  Usage (from your local machine):
#    scp -i <key>.pem ec2-setup.sh ec2-user@<EC2-IP>:~
#    ssh -i <key>.pem ec2-user@<EC2-IP> "bash ~/ec2-setup.sh"
# =============================================================
set -euo pipefail

APP_DIR="/home/ec2-user/unque-api"
REPO_URL="https://github.com/shivamquincy/UnQue-2.0.git"
NODE_VERSION="20"

echo "=============================="
echo " UnQue 2.0 — EC2 Bootstrap"
echo "=============================="

# ── 1. System packages ────────────────────────────────────────
echo "[1/7] Updating system packages..."
sudo yum update -y 2>/dev/null || sudo apt-get update -y

# ── 2. Node.js via NodeSource ─────────────────────────────────
echo "[2/7] Installing Node.js ${NODE_VERSION}..."
if command -v node &>/dev/null; then
  echo "  Node.js $(node -v) already installed, skipping."
else
  curl -fsSL "https://rpm.nodesource.com/setup_${NODE_VERSION}.x" | sudo bash - 2>/dev/null \
    || curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | sudo bash -
  sudo yum install -y nodejs 2>/dev/null || sudo apt-get install -y nodejs
fi

# ── 3. PM2 ───────────────────────────────────────────────────
echo "[3/7] Installing PM2..."
sudo npm install -g pm2

# ── 4. Git clone / pull ───────────────────────────────────────
echo "[4/7] Cloning / updating repository..."
if [ -d "$APP_DIR/.git" ]; then
  cd "$APP_DIR"
  git pull
else
  git clone "$REPO_URL" "$APP_DIR"
  cd "$APP_DIR"
fi

# ── 5. DocumentDB TLS certificate ────────────────────────────
echo "[5/7] Downloading AWS DocumentDB global CA bundle..."
curl -sS https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem \
     -o "$APP_DIR/global-bundle.pem"
echo "  Saved to $APP_DIR/global-bundle.pem"

# ── 6. .env file ──────────────────────────────────────────────
echo "[6/7] Setting up .env ..."
if [ ! -f "$APP_DIR/.env" ]; then
  cp "$APP_DIR/.env.example" "$APP_DIR/.env"
  echo ""
  echo "  *** ACTION REQUIRED ***"
  echo "  Edit $APP_DIR/.env and fill in:"
  echo "    MONGO_URL   — your DocumentDB connection string"
  echo "    JWT_SECRET  — a strong random secret"
  echo "    DOCDB_TLS=true"
  echo "    DOCDB_TLS_CA_FILE=$APP_DIR/global-bundle.pem"
  echo ""
else
  echo "  .env already exists, skipping."
fi

# ── 7. npm install & PM2 start ───────────────────────────────
echo "[7/7] Installing dependencies and starting app..."
npm ci --omit=dev
mkdir -p logs

pm2 start ecosystem.config.cjs --env production || true
pm2 save

# Enable PM2 on reboot
sudo env PATH="$PATH:/usr/bin" pm2 startup systemd -u ec2-user --hp /home/ec2-user

echo ""
echo "=============================="
echo " Done!  App is running via PM2"
echo " Check status: pm2 status"
echo " View logs:    pm2 logs unque-api"
echo "=============================="
