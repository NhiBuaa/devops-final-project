# 📜 DevOps System Contract - Phase 2 (Production)

## 1. Thông tin Network & Routing
- **Domain chính:** `app.nhibuaa.space`
- **SSL/TLS:** Đã bật HTTPS (Let's Encrypt - cert-manager)
- **Frontend URL:** `https://app.nhibuaa.space/` (Port 80)
- **Backend API URL:** `https://app.nhibuaa.space/api` (Port 8080)
- **Grafana URL:** `https://grafana.nhibuaa.space` (Port 3000)

## 2. Thông tin kết nối Database (PostgreSQL)
- **Host:** `postgres-service`
- **Port:** `5432`
- **Username:** `appuser`
- **Database Name:** `appdb`
- **Connection URL:** `postgresql://appuser:<PASSWORD>@postgres-service:5432/appdb`

## 3. Quy ước Biến môi trường (Backend API)
Backend cần đọc các biến sau từ môi trường (Environment Variables):
- **PORT:** `8080`
- **DB_HOST:** `postgres-service`
- **DB_USER:** Được inject từ `backend-secret`
- **DB_PASSWORD:** Được inject từ `backend-secret`
- **METRICS_PORT:** `9090` (Dùng cho Prometheus scrape)

## 4. Health Check (Dành cho Dev)
Để Kubernetes không kill Pod, ứng dụng phải phản hồi HTTP 200 OK tại:
- **Backend:** `/health` và `/health/ready` (Port 8080)
- **Frontend:** `/healthz` (Port 80)