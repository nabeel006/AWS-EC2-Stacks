# Quick Start Guide

## 🎯 What This Application Is

A **safe, educational microservices demo** showing:
- Stack (C), Linked List (Java), Graph (Python) data structures
- Microservices communication via HTTP
- Kubernetes deployment
- Docker containerization

**✅ Security Status: CLEAN** - No malicious code, only standard libraries, all traffic is internal.

## ⚡ Fastest Way to Run Locally

### Prerequisites Check
```bash
# Check if you have everything installed
which minikube || echo "❌ Install minikube: brew install minikube"
which kubectl || echo "❌ Install kubectl: brew install kubectl"
which terraform || echo "❌ Install terraform: brew install terraform"
which docker || echo "❌ Install Docker Desktop"
docker ps || echo "❌ Start Docker Desktop"
```

### One-Command Deployment

```bash
cd /Users/macbook/Desktop/Workspace-DevOps/aks_data_structures/driver
python3 manager.py
```

This single command will:
1. ✅ Start/check Minikube
2. ✅ Build all Docker images
3. ✅ Deploy to Kubernetes
4. ✅ Wait for everything to be ready
5. ✅ Show you the access URL

### Access the Application

After deployment completes, you'll see:
```
Access Points
   Ingress HTTP:  http://<IP>:32080/   # UI at '/', backend under '/api'
```

Open that URL in your browser and click "Fetch Data"!

## 🛑 Cleanup

To stop everything:
```bash
minikube stop
```

To delete all deployments:
```bash
kubectl delete -f k8s/
```

## 📚 Full Documentation

See `ARCHITECTURE_GUIDE.md` for complete details.

