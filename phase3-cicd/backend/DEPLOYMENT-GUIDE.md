# 🚀 Deployment Guide - Backend Service (Startup X)

This document provides detailed instructions for packaging, optimizing, and deploying the Backend service (Node.js Express) to the K3s cluster hosted on AWS.

## 1. Prerequisites
Before proceeding, ensure your local environment is equipped with the following tools:
*   **Docker Desktop**: Required for building and testing images locally.
*   **Kubectl**: To manage and orchestrate the K3s cluster.
*   **Kubeconfig**: The authentication key to connect to the Master Node (Ensure the AWS Public IP is updated).
*   **Docker Hub Account**: Your `thongchau` account for image storage and distribution.

---

## 2. Environment Variables Configuration
The application requires the following variables to establish a connection with the PostgreSQL StatefulSet:

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `PORT` | `8080` | Application listening port |
| `DB_HOST` | `postgres-service` | Internal K8s DNS for the database |
| `DB_USER` | `appuser` | Database access username |
| `DB_PASSWORD` | `password` | Database password (Retrieved from Secrets) |
| `DB_NAME` | `appdb` | Target database name |

---

## 3. Dockerization & Optimization Process

### 3.1. Building the Image (4-Stage Multi-stage Build)
Leverage the optimized Dockerfile to minimize image size and enhance security:
```bash
# Execute the build command within the backend/ directory
docker build -t thongchau/final-devops-backend:latest .
```

### 3.2. Optimization Check
Verify that the image utilizes the `alpine` base to achieve the smallest possible footprint:
```bash
docker images | grep final-devops-backend
```
Goal: Image size should be < 150MB.

### 3.3. Push Image to Registry

```bash
# Login using your generated Personal Access Token (PAT)
docker login -u thongchau

# Push the tagged image to Docker Hub
docker push thongchau/final-devops-backend:latest
```
## 4. Kubernetes (K3s) Deployment

### 4.1. Update Manifests

Verify the `backend/deployment.yaml` file to ensure it references the correct image tag:
```bash
spec:
  containers:
  - name: backend
    image: thongchau/final-devops-backend:latest
```

### 4.2. Execute Deployment

```bash
# Apply configurations to the production namespace
kubectl apply -f backend/deployment.yaml -n production
```

## 5. Verification & Validation

Once deployed, verify the system status using the following steps:

#### 1. Pod Status: `kubectl get pods -n production` (Status must be `Running`).
#### 2. Logs Inspection: `kubectl logs -l app=backend -n production`.
#### 3. Health Check: Access `https://nhibuaa.space/health` (Should return status `UP`).

## 6. Troubleshooting
- `ImagePullBackOff`: Re-verify the image name on Docker Hub and node access permissions.
- Database Connection Failure: Ensure the PostgreSQL Pod is `Running` and the Secrets match the DB configuration.
- `Permission denied`: Check your `kubeconfig` path and SSH key (`.pem`) when executing remote commands.