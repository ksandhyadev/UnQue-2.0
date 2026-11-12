# UnQue 2.0 — College Appointment System

A RESTful API backend that lets students book appointments with professors.  
Built with **Node.js + Express + Mongoose**, deployed on **AWS EC2** and **AWS DocumentDB**.

---

## Table of Contents
1. [Architecture](#architecture)
2. [API Reference](#api-reference)
3. [Local Development](#local-development)
4. [AWS Deployment Guide](#aws-deployment-guide)
   - [Step 1 — DocumentDB cluster](#step-1--documentdb-cluster)
   - [Step 2 — EC2 instance](#step-2--ec2-instance)
   - [Step 3 — Security groups](#step-3--security-groups)
   - [Step 4 — Bootstrap the server](#step-4--bootstrap-the-server)
   - [Step 5 — Configure .env on EC2](#step-5--configure-env-on-ec2)
   - [Step 6 — Start the app](#step-6--start-the-app)
5. [Environment Variables](#environment-variables)
6. [User Flow](#user-flow)

---

## Architecture

```
Internet
   │
   ▼
EC2 (Node.js / PM2)   port 5001
   │   TLS (port 27017)
   ▼
AWS DocumentDB cluster
```

---

## API Reference

### Authentication  (`/users`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/users/register` | — | Register a student or professor |
| POST | `/users/login` | — | Login and receive a JWT |
| GET | `/users/profile/:id` | — | Get a user's public profile |

#### Register body
```json
{
  "name": "Alice",
  "email": "alice@uni.edu",
  "password": "secret123",
  "confirmPassword": "secret123",
  "role": "student"
}
```
`role` must be `"student"` or `"professor"`.

#### Login response
```json
{ "token": "<JWT>", "id": "<userId>", "name": "Alice", "role": "student" }
```

---

### Professor APIs  (`/professor`)
> All routes require `Authorization: Bearer <token>` with a **professor** token.

| Method | Path | Description |
|--------|------|-------------|
| POST | `/professor/availability` | Add a free time slot |
| PATCH | `/professor/availability/:availabilityId` | **[NEW]** Update an existing free slot's timing |
| PATCH | `/professor/cancel-appointments/:studentId` | Cancel all booked appointments with a student |

#### POST `/professor/availability`
```json
{ "startTime": "2024-12-01T09:00:00Z", "endTime": "2024-12-01T10:00:00Z" }
```

#### PATCH `/professor/availability/:availabilityId` ⭐ New API
Updates `startTime` and/or `endTime` of an **existing** free slot **without deleting** it from the database.
```json
{ "startTime": "2024-12-01T10:00:00Z", "endTime": "2024-12-01T11:00:00Z" }
```
- Returns `409 Conflict` if the new window overlaps another slot owned by the same professor.
- Returns `404` if the slot doesn't exist or belongs to another professor.

---

### General / Student APIs  (`/general`)
> All routes require `Authorization: Bearer <token>`.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/general/professor/:professorId/availability` | View all free slots for a professor |
| POST | `/general/book` | Book an appointment |
| GET | `/general/appointments` | View your own booked appointments |

#### POST `/general/book`
```json
{ "professorId": "<id>", "time": "2024-12-01T09:30:00Z" }
```
The `time` must fall within one of the professor's availability windows.

---

## Local Development

```bash
# 1. Clone
git clone https://github.com/shivamquincy/UnQue-2.0.git
cd UnQue-2.0

# 2. Install dependencies
npm install

# 3. Create .env
cp .env.example .env
# Edit .env — set MONGO_URL, JWT_SECRET

# 4. Start MongoDB locally (if not running)
mongod --dbpath /data/db

# 5. Run dev server
npm run dev
```

---

## AWS Deployment Guide

### Step 1 — DocumentDB cluster

1. Open **AWS Console → DocumentDB → Clusters → Create**.
2. Choose **Instance based** cluster (single node is fine for demo).
3. Set a **master username** and **password**.
4. Under *Network*, place the cluster in the **same VPC** you'll use for EC2.
5. Note the **Cluster endpoint** (e.g. `mycluster.cluster-xxxx.us-east-1.docdb.amazonaws.com`).
6. Leave *TLS* **enabled** (default).

> **DocumentDB does NOT support all MongoDB operators.**  
> This app uses: `find`, `findOne`, `save`, `updateMany` — all fully supported.  
> `retryWrites=false` is required in the connection string (DocumentDB limitation).

---

### Step 2 — EC2 instance

1. Launch an **Amazon Linux 2023** (or Ubuntu 22.04) EC2 instance.
2. Instance type: `t3.small` or larger.
3. Place it in the **same VPC and subnet** as your DocumentDB cluster.
4. Attach a key pair so you can SSH in.
5. Under *Security Groups*, open **inbound port 5001** (or 80 if you use a reverse proxy).

---

### Step 3 — Security groups

| Resource | Inbound rule | Source |
|----------|-------------|--------|
| EC2 SG | TCP 22 (SSH) | Your IP |
| EC2 SG | TCP 5001 (API) | 0.0.0.0/0 (or your IP for security) |
| DocDB SG | TCP 27017 | EC2 SG |

---

### Step 4 — Bootstrap the server

```bash
# From your local machine
scp -i ~/.ssh/my-key.pem scripts/ec2-setup.sh ec2-user@<EC2-PUBLIC-IP>:~
ssh -i ~/.ssh/my-key.pem ec2-user@<EC2-PUBLIC-IP>

# On the EC2 instance
bash ~/ec2-setup.sh
```

The script will:
- Install **Node.js 20** via NodeSource
- Install **PM2** globally
- Clone this repository to `/home/ec2-user/unque-api`
- Download the **AWS DocumentDB global TLS CA bundle** (`global-bundle.pem`)
- Create a starter `.env` from `.env.example`
- Run `npm ci` and start the app under PM2

---

### Step 5 — Configure .env on EC2

```bash
# On the EC2 instance
nano /home/ec2-user/unque-api/.env
```

Fill in:

```env
PORT=5001
JWT_SECRET=<your-strong-random-secret>

# DocumentDB connection string
MONGO_URL=mongodb://<user>:<password>@<cluster-endpoint>:27017/unque?tls=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false

# TLS settings
DOCDB_TLS=true
DOCDB_TLS_CA_FILE=/home/ec2-user/unque-api/global-bundle.pem
```

> **Tip:** Generate a secret with  
> `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`

---

### Step 6 — Start the app

```bash
cd /home/ec2-user/unque-api
pm2 reload unque-api --update-env   # pick up the new .env
pm2 status                          # should show "online"
pm2 logs unque-api                  # live log stream
```

The API is now reachable at `http://<EC2-PUBLIC-IP>:5001`.

**For subsequent deploys:**
```bash
bash /home/ec2-user/unque-api/scripts/deploy.sh
```

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `PORT` | No | Server port (default `5001`) |
| `MONGO_URL` | **Yes** | MongoDB / DocumentDB connection string |
| `JWT_SECRET` | **Yes** | Secret for signing JWTs |
| `DOCDB_TLS` | No | Set `true` when connecting to DocumentDB |
| `DOCDB_TLS_CA_FILE` | No | Path to DocumentDB CA bundle (`global-bundle.pem`) |

---

## User Flow

| Step | Actor | API |
|------|-------|-----|
| 1 | Student A1 | `POST /users/login` |
| 2 | Professor P1 | `POST /users/login` |
| 3 | Professor P1 | `POST /professor/availability` |
| 4 | Student A1 | `GET /general/professor/:id/availability` |
| 5 | Student A1 | `POST /general/book` (time T1) |
| 6 | Student A2 | `POST /users/login` |
| 7 | Student A2 | `POST /general/book` (time T2) |
| 8 | Professor P1 | `PATCH /professor/availability/:availabilityId` ⭐ **New** |
| 9 | Professor P1 | `PATCH /professor/cancel-appointments/:studentA1Id` |
| 10 | Student A1 | `GET /general/appointments` → 404 "no pending appointments" |

---

## License

ISC
