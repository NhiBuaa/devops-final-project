# DevOps Final Project

This project implements a team member management application using an end-to-end DevOps workflow, including application development, Docker containerization, Kubernetes deployment, CI/CD automation, and monitoring infrastructure preparation.

## Github Repo: https://github.com/NhiBuaa/devops-final-project
## Video Demo: https://drive.google.com/drive/folders/18no3o_9HO8PgYL_mXtxzK179x0KiX8kY?usp=sharing

## 1. System Overview

The application consists of 3 main components:

- `frontend`: React + Vite + TypeScript, providing the team member management interface
- `backend`: Node.js + Express, providing REST API CRUD operations for members
- `database`: PostgreSQL running as a Kubernetes StatefulSet

Production access flow:

- Users access `https://app.nhibuaa.space`
- Ingress routes `/` to the frontend
- Ingress routes `/api` to the backend
- Backend connects to PostgreSQL through the internal service `postgres-service`

Monitoring domain:

- Grafana: `https://grafana.nhibuaa.space`

---

## 2. Key Features

- Team member CRUD operations (create, update, delete, list)
- Frontend and backend fully containerized with Docker
- Production deployment on K3s
- Ingress + TLS with cert-manager
- Horizontal Pod Autoscaling (HPA) for frontend and backend
- Rolling updates and rollback support
- CI pipelines for frontend and backend
- Multi-environment CD pipeline: staging → manual approval → production

---

## 3. Technology Stack

### Frontend
- React 19
- Vite
- TypeScript
- Tailwind CSS
- Axios

### Backend
- Node.js
- Express
- PostgreSQL
- CORS
- dotenv

### Infrastructure & Deployment
- Docker
- Docker Hub
- Terraform
- Ansible
- K3s / Kubernetes
- GitHub Actions

### Monitoring
- Prometheus
- Grafana
- Loki

### Cloud Platform
- AWS EC2

---

## 4. Project Structure

```text
.
├── app/
│   ├── backend/                  # Node.js + Express API
│   ├── frontend/                 # React + Vite UI
│   └── docker-compose.yml        # Local containerized application
├── phase1-infrastructure/
│   ├── terraform/                # EC2 provisioning, security groups, inventory
│   ├── ansible/                  # K3s, ingress, cert-manager, monitoring setup
│   └── test-idempotency.sh       # Idempotency verification
├── phase2-k8s/                   # Namespace, deployments, services, ingress, HPA
├── phase3-cicd/                  # Rollback scripts, deployment docs, helpers
├── phase4-monitoring/            # Prometheus, Grafana, Loki configuration
├── .github/workflows/            # CI/CD pipelines
├── docs/                         # System contract documentation
└── evidence/                     # Screenshots and deployment evidence
```

---

## 5. Deployment Architecture

### Phase 1 - Infrastructure

Terraform provisions:

- 2 EC2 instances:
  - 1 master node
  - 1 worker node

Additional infrastructure:

- Elastic IP assigned to master node
- Ansible inventory generated automatically

Ansible installs:

- Common node configuration
- K3s master/worker cluster
- Helm tools
- cert-manager
- Monitoring stack

---

### Phase 2 - Kubernetes

Deployment includes:

- Production namespace
- PostgreSQL StatefulSet + persistent volume
- Backend Deployment + Service + HPA
- Frontend Deployment + Service + HPA
- Production Ingress
- TLS certificates via Let's Encrypt

---

### Phase 3 - CI/CD

#### `ci-frontend.yml`

Pipeline steps:

- Install dependencies
- Lint
- Build
- Trivy scan
- Build and push Docker image when pushing to `main` or `develop`

---

#### `ci-backend.yml`

Pipeline steps:

- Lint
- Test
- Trivy SAST scan
- Build application
- Build and push Docker image
- Update image tags in Kubernetes manifests

---

#### `cd.yml`

Pipeline flow:

- Triggered after successful CI or manually
- Deploy to `staging`
- Run health checks
- Wait for manual approval
- Deploy to `production`
- Auto rollback if rollout or health checks fail

---

### Phase 4 - Monitoring

Configuration directories provided for:

- Prometheus
- Grafana
- Loki

Includes dashboards and deployment evidence for production observability.

---

## 6. Current API Endpoints

The backend currently exposes:

- `GET /health`
- `GET /api/members`
- `POST /api/members`
- `PUT /api/members/:id`
- `DELETE /api/members/:id`

Example member payload:

```json
{
  "name": "Nguyen Van A",
  "role": "Backend Developer"
}
```

---

## 7. Important Environment Variables

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

---

## 8. Running Locally

### Option 1 - Run frontend/backend separately

#### Backend

```bash
cd app/backend
npm ci
node index.js
```

#### Frontend

```bash
cd app/frontend
npm ci
npm run dev
```

Notes:

- Frontend calls API through `VITE_API_URL`
- For full local execution, create a frontend `.env` file:

```env
VITE_API_URL=http://localhost:8080/api
```

---

### Option 2 - Run using Docker Compose

```bash
cd app
docker compose up --build
```

Current compose file exposes:

- Frontend on port `80`
- Backend on port `8080`

---

## 9. Infrastructure and Application Deployment

### 9.1 Provision infrastructure with Terraform

```bash
cd phase1-infrastructure/terraform
terraform init
terraform plan
terraform apply
```

---

### 9.2 Configure cluster with Ansible

```bash
cd phase1-infrastructure/ansible
ansible-playbook -i inventory/hosts.ini site.yml
```

---

### 9.3 Deploy application to Kubernetes

```bash
cd phase2-k8s
./deploy.sh
```

---

## 10. Manual Rollback

Rollback script location:

- `phase3-cicd/rollback.sh`

Examples:

```bash
./phase3-cicd/rollback.sh production history
./phase3-cicd/rollback.sh production undo
./phase3-cicd/rollback.sh production revision 5 3
./phase3-cicd/rollback.sh production tag <dockerhub_user> <commit_sha>
```

---

## 11. Required CI/CD Secrets

The repository requires the following GitHub Secrets:

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

---

## 12. Evidence and Documentation

System contract documentation:

- `docs/contract.md`

Deployment evidence:

- `evidence/phase1-infrastructure/`
- `evidence/phase2-k8s/`
- `evidence/phase3-cicd/`

---

## 13. Notes

- This `README.md` reflects the repository's current state
- Some workflows reference slightly different image/tag naming conventions between frontend and backend; verify manifests before production deployment
- The current `app/docker-compose.yml` does not include PostgreSQL, so local compose execution is most suitable when backend does not depend on the database or when an external database is already available

---

## 14. Author

This project was developed for DevOps practice purposes, including:

- Building a sample application
- Infrastructure automation
- Kubernetes deployment
- CI/CD pipeline design
- Production monitoring and operations preparation
