# Video Demonstration & Submission Guide

This guide provides an exact script and step-by-step checklist to record both required videos for your submission.

---

## Video 1: API User Flow Demonstration (Postman + Live DocumentDB)

### Goal:
Demonstrate the complete 10-step user flow hitting your **AWS EC2 instance** (`http://<EC2-IP>:5001`) backed by **AWS DocumentDB**, showing live database queries pre- and post-booking.

### Preparation:
1. Open **Postman**:
   - Import `postman/UnQue_2.0_API_Collection.json`
   - Import `postman/UnQue_AWS_EC2.postman_environment.json`
   - Set the `baseUrl` variable in Postman to `http://<EC2_PUBLIC_IP>:5001`
2. Open a terminal SSH'd into your EC2 instance and connect to DocumentDB using `mongosh`:
   ```bash
   mongosh --host <cluster-endpoint>:27017 \
     --tls --tlsCAFile /home/ec2-user/unque-api/global-bundle.pem \
     --username <docdb-username> --password
   ```
   Switch to the database:
   ```javascript
   use unque;
   ```

### Recording Script (Step-by-Step):

| Step | Action in Postman / Terminal | What to Highlight on Screen |
|---|---|---|
| **Intro** | Show Postman `baseUrl` pointing to EC2 IP (not localhost!) | Point out that requests go over internet to EC2 |
| **1. Student A1 Auth** | Run `1a. Register Student A1` then `1b. Login Student A1` | Show `200 OK`, returned JWT token saved automatically |
| **2. Prof P1 Auth** | Run `2a. Register Professor P1` then `2b. Login Professor P1` | Show `role: professor` and JWT token |
| **3. Prof Availability** | Run `3a`, `3b`, and `3c` to create time slots | Show `201 Created` with formatted start/end times |
| **Live DB Check 1** | In `mongosh` terminal, run: `db.availabilities.find().pretty()` | Show slots persisted in AWS DocumentDB |
| **4. View Available Slots** | Run `04 - Student A1 views available slots for Prof P1` | Show formatted slots returned to student |
| **Live DB (Pre-booking)** | In `mongosh`: `db.appointments.find().pretty()` | Show that appointments collection is empty / 0 bookings |
| **5. Book T1** | Run `05 - Student A1 books appointment with Prof P1 (Time T1)` | Show `201 Created` with status `"booked"` |
| **Live DB (Post-booking 1)** | In `mongosh`: `db.appointments.find().pretty()` | **Live Data Highlight**: Show Student A1's booking in DocumentDB! |
| **6. Student A2 Auth** | Run `6a. Register Student A2` then `6b. Login Student A2` | Show Student A2 authenticated |
| **7. Book T2** | Run `07 - Student A2 books appointment with Prof P1 (Time T2)` | Show `201 Created` for Student A2 |
| **Live DB (Post-booking 2)** | In `mongosh`: `db.appointments.find().pretty()` | Show both appointments in DocumentDB |
| **8. [NEW API] Update Slot** | Run `08 - [NEW API] Prof P1 updates timing of free slot` | **Key requirement**: Show `PATCH /professor/availability/:id` updates slot without deleting it (`200 OK`) |
| **Live DB (Slot Update)** | In `mongosh`: `db.availabilities.find({ _id: ObjectId("...") }).pretty()` | Show the updated time reflected in DocumentDB |
| **9. Cancel Appointment** | Run `09 - Prof P1 cancels appointments with Student A1` | Show success message: appointment status changed to `"canceled"` |
| **Live DB (Post-cancellation)**| In `mongosh`: `db.appointments.find().pretty()` | Show status changed to `"canceled"` |
| **10. Check Appointments** | Run `10 - Student A1 checks appointments` | Show `404 Not Found` with message: `"You have no pending appointments"` |

---

## Video 2: DevOps Setup Walkthrough (AWS Dashboard & Code)

### Goal:
Show the cloud architecture, configuration on AWS, and all modified code and deployment scripts.

### Walkthrough Outline:
1. **AWS EC2 Dashboard**:
   - Show EC2 instance state (`running`), Instance Type, Public IPv4 address.
   - Show Security Groups:
     - Inbound port `22` (SSH)
     - Inbound port `5001` (API application port)
2. **AWS DocumentDB Dashboard**:
   - Show DocumentDB cluster status (`available`), Cluster Endpoint.
   - Show Security Group configuration (Inbound TCP port `27017` restricted to EC2's security group).
   - Show TLS configuration is **Enabled**.
3. **EC2 Server Terminal**:
   - Run `pm2 status` showing `unque-api` in cluster mode (`online`).
   - Run `pm2 logs --lines 20` showing clean database connection to DocumentDB.
   - Show `global-bundle.pem` certificate in `/home/ec2-user/unque-api`.
   - Show `.env` configuration (hide password):
     ```env
     DOCDB_TLS=true
     DOCDB_TLS_CA_FILE=/home/ec2-user/unque-api/global-bundle.pem
     ```
4. **Code Changes Walkthrough**:
   - **New API**: `controllers/proff.js` & `routes/proff.js` (`updateAvailability` PATCH endpoint).
   - **DocumentDB Connection**: `index.js` (TLS options, `DOCDB_TLS`, `DOCDB_TLS_CA_FILE`).
   - **Bug fixes**: `models/user.js` syntax fix, `models/appointment.js` enum fix.
   - **DevOps Artifacts**:
     - `Dockerfile` (multi-stage build with AWS CA bundle)
     - `ecosystem.config.cjs` (PM2 cluster configuration)
     - `scripts/ec2-setup.sh` (one-shot automated bootstrap)
     - `scripts/deploy.sh` (zero-downtime redeployment)
5. **GitHub Repository**:
   - Show the commit history on your GitHub repository with all changes pushed.
