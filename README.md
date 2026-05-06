# DevOps Final Project

Dự án này triển khai một ứng dụng quản lý thành viên nhóm theo hướng DevOps end-to-end: phát triển ứng dụng, đóng gói bằng Docker, triển khai lên Kubernetes, tự động hóa CI/CD và chuẩn bị nền tảng monitoring.

## 1. Tổng quan hệ thống

Ứng dụng gồm 3 thành phần chính:

- `frontend`: React + Vite + TypeScript, giao diện quản lý danh sách thành viên.
- `backend`: Node.js + Express, cung cấp REST API CRUD cho thành viên.
- `database`: PostgreSQL chạy dạng StatefulSet trên Kubernetes.

Luồng truy cập production:

- Người dùng truy cập `https://app.nhibuaa.space`
- Ingress route `/` vào frontend
- Ingress route `/api` vào backend
- Backend kết nối PostgreSQL qua service nội bộ `postgres-service`

Monitoring domain:

- Grafana: `https://grafana.nhibuaa.space`

## 2. Tính năng chính

- CRUD thành viên nhóm: thêm, sửa, xóa, xem danh sách.
- Frontend và backend containerized bằng Docker.
- Triển khai production trên K3s.
- Ingress + TLS với cert-manager.
- HPA cho frontend và backend.
- Rolling update và rollback khi deploy lỗi.
- CI cho frontend và backend.
- CD nhiều môi trường: staging -> manual approval -> production.

## 3. Công nghệ sử dụng

- Frontend: React 19, Vite, TypeScript, Tailwind CSS, Axios
- Backend: Node.js, Express, PostgreSQL, CORS, dotenv
- Container: Docker, Docker Hub
- IaC và cấu hình máy chủ: Terraform, Ansible
- Orchestration: K3s / Kubernetes
- CI/CD: GitHub Actions
- Monitoring: Prometheus, Grafana, Loki
- Cloud: AWS EC2

## 4. Cấu trúc thư mục

```text
.
├── app/
│   ├── backend/                  # API Node.js + Express
│   ├── frontend/                 # UI React + Vite
│   └── docker-compose.yml        # Chạy app container ở local
├── phase1-infrastructure/
│   ├── terraform/                # Tạo EC2, security group, inventory
│   ├── ansible/                  # Cài K3s, ingress, cert-manager, monitoring
│   └── test-idempotency.sh       # Kiểm tra idempotency
├── phase2-k8s/                   # Namespace, deployments, services, ingress, HPA
├── phase3-cicd/                  # Rollback script, tài liệu deploy, cấu hình phụ trợ
├── phase4-monitoring/            # Prometheus, Grafana, Loki
├── .github/workflows/            # CI/CD pipelines
├── docs/                         # Tài liệu contract hệ thống
└── evidence/                     # Ảnh/chứng cứ cho các phase
```

## 5. Kiến trúc triển khai

### Phase 1 - Infrastructure

- Terraform tạo 2 EC2:
  - 1 master node
  - 1 worker node
- Gán Elastic IP cho master
- Sinh inventory cho Ansible
- Ansible cài:
  - cấu hình chung cho node
  - K3s master/worker
  - Helm tools
  - cert-manager
  - monitoring stack

### Phase 2 - Kubernetes

- Namespace production
- PostgreSQL StatefulSet + persistent volume
- Backend Deployment + Service + HPA
- Frontend Deployment + Service + HPA
- Ingress cho domain production
- TLS certificate với Let's Encrypt

### Phase 3 - CI/CD

- `ci-frontend.yml`
  - cài dependencies
  - lint
  - build
  - scan Trivy
  - build/push Docker image khi push lên `main` hoặc `develop`

- `ci-backend.yml`
  - lint
  - test
  - SAST scan bằng Trivy
  - build app
  - build/push Docker image
  - cập nhật image tag trong manifest K8s

- `cd.yml`
  - trigger sau khi CI thành công hoặc chạy manual
  - deploy `staging`
  - health check
  - chờ manual approval
  - deploy `production`
  - auto rollback nếu rollout/health check thất bại

### Phase 4 - Monitoring

- Có thư mục cấu hình cho:
  - Prometheus
  - Grafana
  - Loki
- Có dashboard và evidence phục vụ quan sát hệ thống production

## 6. API hiện tại

Backend đang cung cấp các endpoint:

- `GET /health`
- `GET /api/members`
- `POST /api/members`
- `PUT /api/members/:id`
- `DELETE /api/members/:id`

Ví dụ payload tạo/cập nhật thành viên:

```json
{
  "name": "Nguyen Van A",
  "role": "Backend Developer"
}
```

## 7. Biến môi trường quan trọng

### Backend

```env
PORT=8080
DB_HOST=postgres-service
DB_USER=appuser
DB_PASSWORD=password
DB_NAME=appdb
CORS_ORIGIN=*
```

### Frontend

```env
VITE_API_URL=https://app.nhibuaa.space/api
```

## 8. Chạy dự án ở local

### Cách 1 - Chạy frontend/backend riêng

Backend:

```bash
cd app/backend
npm ci
node index.js
```

Frontend:

```bash
cd app/frontend
npm ci
npm run dev
```

Lưu ý:

- Frontend mặc định gọi API qua `VITE_API_URL`
- Nếu chạy local hoàn toàn, nên tạo `.env` cho frontend:

```env
VITE_API_URL=http://localhost:8080/api
```

### Cách 2 - Chạy bằng Docker Compose

```bash
cd app
docker compose up --build
```

Mặc định file compose hiện tại chạy:

- frontend tại port `80`
- backend tại port `8080`

## 9. Triển khai hạ tầng và ứng dụng

### 9.1. Tạo hạ tầng bằng Terraform

```bash
cd phase1-infrastructure/terraform
terraform init
terraform plan
terraform apply
```

### 9.2. Cấu hình cluster bằng Ansible

```bash
cd phase1-infrastructure/ansible
ansible-playbook -i inventory/hosts.ini site.yml
```

### 9.3. Deploy ứng dụng lên Kubernetes

```bash
cd phase2-k8s
./deploy.sh
```

## 10. Rollback thủ công

Script rollback nằm tại:

- `phase3-cicd/rollback.sh`

Một số ví dụ:

```bash
./phase3-cicd/rollback.sh production history
./phase3-cicd/rollback.sh production undo
./phase3-cicd/rollback.sh production revision 5 3
./phase3-cicd/rollback.sh production tag <dockerhub_user> <commit_sha>
```

## 11. CI/CD secrets cần có

Để pipeline hoạt động đầy đủ, repo cần chuẩn bị các GitHub Secrets như:

- `DOCKER_USERNAME`
- `DOCKER_TOKEN`
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- `KUBECONFIG_B64`
- `STAGING_DB_USER`
- `STAGING_DB_PASSWORD`
- `STAGING_JWT_SECRET`
- `PROD_DB_USER`
- `PROD_DB_PASSWORD`
- `PROD_JWT_SECRET`
- `MY_GIT_TOKEN`
- `VITE_API_URL`

## 12. Bằng chứng và tài liệu

- Tài liệu contract hệ thống: `docs/contract.md`
- Ảnh minh chứng:
  - `evidence/phase1-infrastructure/`
  - `evidence/phase2-k8s/`

## 13. Điểm cần lưu ý

- `README.md` này mô tả theo trạng thái repo hiện tại.
- Một số workflow đang tham chiếu tới tên image/tag hơi khác nhau giữa frontend và backend, vì vậy khi demo nên kiểm tra lại manifest/image convention trước khi chạy production.
- File `app/docker-compose.yml` hiện chưa bao gồm PostgreSQL, nên cách chạy local bằng compose phù hợp nhất khi backend không phụ thuộc DB hoặc khi DB đã có sẵn bên ngoài.

## 14. Tác giả

Đồ án phục vụ mục tiêu thực hành DevOps:

- xây dựng ứng dụng mẫu
- tự động hóa hạ tầng
- triển khai Kubernetes
- thiết kế CI/CD pipeline
- chuẩn bị giám sát và vận hành production
