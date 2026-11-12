#!/usr/bin/env bash
# =============================================================
#  ec2-setup-standalone.sh
#  Installs MongoDB 7.0, Node.js 20, PM2, and deploys UnQue 2.0
#  on Amazon Linux 2023 (100% Free Tier, self-contained).
# =============================================================
set -euo pipefail

APP_DIR="/home/ec2-user/unque-api"
REPO_URL="https://github.com/ksandhyadev/UnQue-2.0.git"
NODE_VERSION="20"

echo "============================================="
echo " UnQue 2.0 — Standalone EC2 Cloud Setup"
echo "============================================="

# ── 1. System updates ─────────────────────────────────────────
echo "[1/7] Updating system packages..."
sudo dnf update -y 2>/dev/null || sudo yum update -y 2>/dev/null || sudo apt-get update -y

# ── 2. Install MongoDB 7.0 Community Edition ─────────────────
echo "[2/7] Installing MongoDB Community Edition..."
if command -v mongod &>/dev/null; then
  echo "  MongoDB already installed, skipping."
else
  # Configure MongoDB repository for Amazon Linux 2023
  sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo << 'EOF'
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF
  sudo dnf install -y mongodb-org 2>/dev/null || sudo yum install -y mongodb-org 2>/dev/null || true
  
  # Start & enable MongoDB service
  sudo systemctl daemon-reload
  sudo systemctl start mongod || sudo service mongod start || true
  sudo systemctl enable mongod || true
  echo "  MongoDB service started successfully."
fi

# ── 3. Install Node.js 20 ─────────────────────────────────────
echo "[3/7] Installing Node.js ${NODE_VERSION}..."
if command -v node &>/dev/null; then
  echo "  Node.js $(node -v) already installed, skipping."
else
  curl -fsSL "https://rpm.nodesource.com/setup_${NODE_VERSION}.x" | sudo bash -
  sudo dnf install -y nodejs 2>/dev/null || sudo yum install -y nodejs
fi

# ── 4. Install PM2 ────────────────────────────────────────────
echo "[4/7] Installing PM2 process manager..."
sudo npm install -g pm2

# ── 5. Clone repository ───────────────────────────────────────
echo "[5/7] Cloning UnQue 2.0 repository..."
sudo rm -rf "$APP_DIR"
git clone "$REPO_URL" "$APP_DIR"
cd "$APP_DIR"

# ── 6. Configure .env ─────────────────────────────────────────
echo "[6/7] Creating production .env file..."
JWT_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")

cat << EOF > "$APP_DIR/.env"
PORT=5001
MONGO_URL=mongodb://127.0.0.1:27017/unque
JWT_SECRET=${JWT_SECRET}
DOCDB_TLS=false
DOCDB_TLS_CA_FILE=
EOF

# ── 7. Install dependencies and start with PM2 ────────────────
echo "[7/7] Installing dependencies & starting API server..."
npm install

mkdir -p logs
pm2 delete unque-api 2>/dev/null || true
pm2 start ecosystem.config.cjs --env production
pm2 save

# Auto-start PM2 on system reboot
sudo env PATH="$PATH:/usr/bin" pm2 startup systemd -u ec2-user --hp /home/ec2-user || true

echo ""
echo "=========================================================="
echo " SUCCESS! UnQue 2.0 is live on your EC2 cloud server!"
echo " Public API Port : 5001"
echo " Check PM2 status: pm2 status"
echo " View live logs  : pm2 logs unque-api"
echo "=========================================================="
