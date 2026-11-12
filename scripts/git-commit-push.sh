#!/usr/bin/env bash
set -e

# Move to repo root
cd "$(dirname "$0")/.."

# Stage all files
git add -A

# Commit
git commit -m "feat: complete cloud deployment setup — DocumentDB, new update API, EC2 & Postman

Changes:
- models/user.js: fix syntax error
- models/appointment.js: standardise status enum ('canceled')
- index.js: DocumentDB TLS/CA support via DOCDB_TLS; 0.0.0.0 host binding
- controllers/proff.js & routes/proff.js: add updateAvailability (PATCH /professor/availability/:id)
- .env.example: DocumentDB and JWT configuration template
- Dockerfile: production multi-stage image with AWS CA bundle
- ecosystem.config.cjs: PM2 cluster-mode configuration
- scripts/ec2-setup.sh: one-shot EC2 bootstrap script
- scripts/deploy.sh: zero-downtime redeployment script
- postman/: Postman collection and environment with automated token/ID flow
- docs/VIDEO_DEMO_GUIDE.md: complete script for recording Demo & DevOps videos
- README.md: comprehensive API reference and AWS setup documentation"

# Push to main
git push origin main
