# EC2 Jenkins Deployment - Quick Reference

## 🚀 Quick Setup (3 Steps)

### 1. Launch EC2 & Run Setup Script
```bash
# SSH into your EC2 instance
ssh -i your-key.pem ubuntu@<EC2-IP>

# Download and run setup script
wget https://raw.githubusercontent.com/YOUR-USERNAME/aks_data_structures/main/jenkins/setup-ec2-jenkins.sh
chmod +x setup-ec2-jenkins.sh
./setup-ec2-jenkins.sh

# Log out and back in for Docker group changes
exit
ssh -i your-key.pem ubuntu@<EC2-IP>

# Start Minikube
minikube start --driver=docker --memory=4096 --cpus=2
```

### 2. Configure Jenkins
```bash
# Access Jenkins at: http://<EC2-IP>:8080
# Get initial password:
cat ~/.jenkins/secrets/initialAdminPassword

# In Jenkins UI:
# 1. Install suggested plugins
# 2. Create admin user
# 3. Add credentials (Manage Jenkins → Manage Credentials):
#    - github-pat-token (Secret text)
#    - ec2-ssh-key (SSH Username with private key)
#    - ec2-host-ip (Secret text with EC2 IP)
```

### 3. Create Pipeline
```bash
# In Jenkins:
# 1. New Item → Pipeline → Name: aks-data-structures-deployment
# 2. Configure:
#    - GitHub project: https://github.com/YOUR-USERNAME/aks_data_structures
#    - Build Triggers: GitHub hook trigger for GITScm polling
#    - Pipeline: Pipeline script from SCM
#    - Repository URL: https://github.com/YOUR-USERNAME/aks_data_structures.git
#    - Credentials: github-pat-token
#    - Script Path: Jenkinsfile-EC2
# 3. Save and Build Now!
```

## 📋 Required Credentials in Jenkins

| Credential ID | Type | Description | Value |
|--------------|------|-------------|-------|
| `github-pat-token` | Secret text | GitHub Personal Access Token | Your GitHub PAT |
| `ec2-ssh-key` | SSH Username with private key | EC2 SSH access | Username: ubuntu, Private key: your .pem file |
| `ec2-host-ip` | Secret text | EC2 Public IP | Your EC2 public IP address |

## 🔐 Security Group Ports

| Port | Purpose | Source |
|------|---------|--------|
| 22 | SSH | Your IP |
| 8080 | Jenkins UI | 0.0.0.0/0 |
| 32080 | Application UI | 0.0.0.0/0 |
| 5000 | Backend API (optional) | 0.0.0.0/0 |

## 📝 Update Jenkinsfile-EC2

Before first build, update this line in `Jenkinsfile-EC2`:
```groovy
REPO_URL = 'github.com/YOUR-USERNAME/aks_data_structures.git'
```

## 🎯 Access URLs After Deployment

- **Jenkins**: `http://<EC2-IP>:8080`
- **Application UI**: `http://<EC2-IP>:32080/`
- **Backend API**: `http://<EC2-IP>:32080/api/dashboard`

## 🔍 Verification Commands (on EC2)

```bash
# Check all services
sudo systemctl status jenkins
minikube status
kubectl get pods
kubectl get services

# Check application
curl http://$(minikube ip):32080/
curl http://$(minikube ip):32080/api/dashboard

# View logs
sudo journalctl -u jenkins -f
kubectl logs -f deployment/backend-deployment
```

## 🛠️ Common Issues & Fixes

### Jenkins won't start
```bash
sudo systemctl restart jenkins
sudo journalctl -u jenkins -n 50
```

### Minikube issues
```bash
minikube delete
minikube start --driver=docker --memory=4096 --cpus=2
```

### Docker permission denied
```bash
# Log out and back in, or:
newgrp docker
```

### Pipeline fails at SSH
```bash
# Verify SSH key in Jenkins credentials
# Test manually: ssh -i key.pem ubuntu@<EC2-IP>
```

### Pods not starting
```bash
kubectl get pods
kubectl describe pod <pod-name>
eval $(minikube docker-env)
# Rebuild images if needed
```

## 🔄 GitHub Webhook Setup

1. GitHub Repo → Settings → Webhooks → Add webhook
2. Payload URL: `http://<EC2-IP>:8080/github-webhook/`
3. Content type: `application/json`
4. Events: Just the push event
5. Active: ✅

## 📊 Monitoring

```bash
# Jenkins logs
sudo journalctl -u jenkins -f

# Kubernetes resources
kubectl get all
kubectl top nodes
kubectl top pods

# Application logs
kubectl logs -f deployment/ui-deployment
kubectl logs -f deployment/backend-deployment
kubectl logs -f deployment/stack-deployment
kubectl logs -f deployment/linkedlist-deployment
kubectl logs -f deployment/graph-deployment
```

## 🧹 Cleanup

```bash
# Delete Kubernetes resources
kubectl delete -f ~/aks_data_structures/k8s/

# Or use Terraform
cd ~/aks_data_structures/terraform/local
terraform destroy -auto-approve

# Stop Minikube
minikube stop

# Stop Jenkins
sudo systemctl stop jenkins
```

## 📚 Full Documentation

For complete setup instructions, see:
- **EC2_JENKINS_SETUP_GUIDE.md** - Complete step-by-step guide
- **EC2_SETUP.md** - Detailed EC2 setup
- **README.md** - Project overview

## 🆘 Need Help?

1. Check Jenkins console output for errors
2. Check EC2 security group settings
3. Verify all credentials are correctly configured
4. Check Minikube status: `minikube status`
5. Check Docker: `docker ps`
6. Review logs: `sudo journalctl -u jenkins -f`

---

**Quick Start**: Run `setup-ec2-jenkins.sh` on EC2, configure Jenkins credentials, create pipeline, build! 🚀
