# Architecture Guide & Local Setup

## 📋 Overview

This is a **legitimate educational/demo application** showcasing a microservices architecture with data structures implemented in multiple programming languages and deployed on Kubernetes.

## 🔍 Security Assessment

✅ **SAFE - This is a simple educational application**
- No external network calls or data exfiltration
- No obfuscated or suspicious code
- Only uses standard, well-known libraries (Flask, requests, etc.)
- All network communication is internal to the Kubernetes cluster
- Standard microservices patterns with no malicious behavior

## 🏗️ Architecture

This application demonstrates a microservices architecture with 5 main components:

### 1. **Stack Service (C Language)**
- **Location**: `stack/stack_server.c`
- **Port**: 5001
- **Purpose**: Implements a stack data structure using pure C
- **Endpoints**:
  - `POST /push?val=<number>` - Push a value onto the stack
  - `GET /pop` - Pop a value from the stack
  - `GET /` - Health check

### 2. **Linked List Service (Java)**
- **Location**: `linkedlist/LinkedListService.java`
- **Port**: 5002
- **Purpose**: Implements a doubly linked list in Java
- **Endpoints**:
  - `GET /add?val=<string>` - Add a node to the list
  - `GET /display` - Display the current list state

### 3. **Graph Service (Python/Flask)**
- **Location**: `graph/graph_service.py`
- **Port**: 5003
- **Purpose**: Returns hardcoded graph data (nodes and edges)
- **Endpoints**:
  - `GET /graph` - Returns graph structure as JSON
  - `GET /health` - Health check

### 4. **Backend Service (Python/Flask) - Aggregator**
- **Location**: `backend/app.py`
- **Port**: 5000
- **Purpose**: Aggregates data from all three microservices
- **Endpoints**:
  - `GET /dashboard` - Calls all services and returns combined JSON
  - `GET /health` - Health check

### 5. **UI Service (HTML/JavaScript)**
- **Location**: `ui/`
- **Port**: 80
- **Purpose**: Web frontend that displays data from all services
- **Features**: Simple dashboard with a button to fetch and display data

### Infrastructure Components

- **Kubernetes**: Orchestrates all services
- **Nginx Ingress**: Routes external traffic to services
- **Terraform**: Infrastructure as Code for deployment
- **Docker**: Containerizes all services

## 📊 Data Flow

```
User Browser
    ↓
Nginx Ingress (Port 32080)
    ↓
    ├─→ UI Service (/) → Frontend HTML/JS
    └─→ Backend Service (/api) → Python Flask
            ↓
            ├─→ Stack Service (C) - HTTP requests
            ├─→ Linked List Service (Java) - HTTP requests
            └─→ Graph Service (Python) - HTTP requests
```

## 🚀 Local Setup Instructions

### Prerequisites

You need the following installed on your Mac:

1. **Docker Desktop** (or Docker + Docker Compose)
2. **Minikube** (local Kubernetes)
3. **kubectl** (Kubernetes CLI)
4. **Terraform** (for IaC deployment)
5. **Python 3.9+** (for driver script)
6. **Java JDK 17** (for building LinkedList service)
7. **GCC** (for building Stack service - usually pre-installed on macOS)

### Installation Steps

#### 1. Install Homebrew (if not already installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Install Minikube
```bash
brew install minikube
```

#### 3. Install kubectl
```bash
brew install kubectl
```

#### 4. Install Terraform
```bash
brew install terraform
```

#### 5. Install Docker Desktop
Download from: https://www.docker.com/products/docker-desktop

#### 6. Verify Installations
```bash
minikube version
kubectl version --client
terraform version
docker --version
```

### Running the Application

#### Option 1: Using the Automated Driver Script (Recommended)

The project includes an automated deployment script:

```bash
cd /Users/macbook/Desktop/Workspace-DevOps/aks_data_structures
cd driver
pip install -r requirements.txt  # Install driver dependencies
python manager.py
```

This script will:
1. Check/start Minikube
2. Configure Docker to use Minikube's Docker daemon
3. Build all Docker images
4. Deploy to Kubernetes using Terraform
5. Wait for pods to be ready
6. Display access URLs

#### Option 2: Manual Deployment

##### Step 1: Start Minikube
```bash
minikube start
```

##### Step 2: Point Docker to Minikube
```bash
eval $(minikube docker-env)
```

##### Step 3: Build Docker Images
```bash
cd /Users/macbook/Desktop/Workspace-DevOps/aks_data_structures

# Build each service
docker build -t stack-service:latest ./stack
docker build -t linkedlist-service:latest ./linkedlist
docker build -t graph-service:latest ./graph
docker build -t backend-service:latest ./backend
docker build -t ui-service:latest ./ui
```

##### Step 4: Deploy to Kubernetes using Terraform
```bash
cd terraform/local
terraform init
terraform apply -auto-approve
```

##### Step 5: Wait for Pods to be Ready
```bash
kubectl get pods -w
# Wait until all pods show STATUS: Running and READY: 1/1
```

##### Step 6: Get Access URL
```bash
minikube ip
# Note the IP, then access: http://<minikube-ip>:32080
```

Or use port-forward:
```bash
kubectl port-forward svc/ui-service 8080:80
# Access at: http://localhost:8080
```

### Accessing the Application

Once deployed, you can access:

- **Web UI**: `http://<minikube-ip>:32080/` or via port-forward
- **Backend API**: `http://<minikube-ip>:32080/api/dashboard`

### Useful Commands

```bash
# Check pod status
kubectl get pods

# Check services
kubectl get services

# View logs for a specific service
kubectl logs -f deployment/backend-deployment

# Delete everything
kubectl delete -f k8s/

# Restart Minikube
minikube stop
minikube start
```

## ☁️ Preparing for Cloud Deployment (Kubernetes)

To deploy this to a cloud Kubernetes cluster (like AKS, EKS, or GKE), you'll need to:

### 1. Modify Docker Image Strategy

Currently, images use `imagePullPolicy: Never` (for local). For cloud:

- Push images to a container registry (Docker Hub, ACR, ECR, GCR)
- Update Kubernetes YAMLs to use registry URLs
- Change `imagePullPolicy` to `Always` or remove it (defaults to `Always`)

### 2. Update Service URLs in `backend/app.py`

The current URLs use Kubernetes DNS service names which work in any K8s cluster:
- `http://stack-service:5001` ✅ (works in cloud too)
- `http://linkedlist-service:5002` ✅ (works in cloud too)
- `http://graph-service:5003` ✅ (works in cloud too)

### 3. Configure Ingress

Update `k8s/ingress.yaml` to use cloud-specific ingress annotations:
- For AKS: Use Azure Application Gateway or NGINX Ingress
- For EKS: Use AWS Load Balancer Controller
- For GKE: Use Google Cloud Load Balancer

### 4. Update Terraform Providers

Modify `terraform/local/providers.tf` to point to your cloud cluster context:
```hcl
provider "kubectl" {
  config_path    = "~/.kube/config"
  config_context = "<your-cloud-cluster-context>"  # e.g., "my-aks-cluster"
}
```

### 5. Create Cloud-Specific Terraform Directory

Create a new directory like `terraform/cloud/` with:
- Updated provider configuration
- Image pull secrets if using private registry
- Cloud-specific ingress configuration

## 🔧 Troubleshooting

### Issue: Minikube won't start
**Solution**: Check Docker Desktop is running and has enough resources (4GB RAM minimum)

### Issue: Images not found
**Solution**: Make sure you've run `eval $(minikube docker-env)` before building images

### Issue: Pods stuck in Pending/ImagePullBackOff
**Solution**: 
- Verify images are built: `docker images`
- Check imagePullPolicy is set to `Never` for local
- Verify Minikube is using the same Docker daemon

### Issue: Services not accessible
**Solution**:
- Check ingress controller is running: `kubectl get pods -n ingress-nginx`
- Verify service endpoints: `kubectl get endpoints`
- Check service selectors match pod labels

## 📝 Summary

This is a **clean, educational microservices demo** that:
- Shows how to containerize services in C, Java, and Python
- Demonstrates Kubernetes deployments
- Uses infrastructure as code (Terraform)
- Implements a simple aggregator pattern
- Provides a web UI for visualization

Perfect for learning Kubernetes, Docker, and microservices architecture! 🎓

