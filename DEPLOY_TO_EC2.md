# Deploy to EC2 with Jenkins - Complete Guide

This document provides a complete overview of deploying your AKS Data Structures microservices application to AWS EC2 using Jenkins CI/CD.

## 📚 Documentation Structure

Your project now includes comprehensive EC2 deployment documentation:

### Main Files Created

1. **`Jenkinsfile-EC2`** (Root directory)
   - Jenkins pipeline for EC2 deployment
   - Handles SSH, git clone with PAT, Docker builds, Terraform deployment
   - **Action Required**: Update `REPO_URL` with your GitHub username

2. **`jenkins/EC2_JENKINS_SETUP_GUIDE.md`**
   - Complete step-by-step setup guide (most detailed)
   - Covers EC2 launch, installation, Jenkins config, pipeline creation
   - **Start here for first-time setup**

3. **`jenkins/EC2_QUICK_REFERENCE.md`**
   - Quick reference card for experienced users
   - 3-step setup summary
   - Common commands and troubleshooting

4. **`jenkins/DEPLOYMENT_CHECKLIST.md`**
   - Interactive checklist for deployment
   - Ensures no steps are missed
   - Great for verification

5. **`jenkins/setup-ec2-jenkins.sh`**
   - Automated installation script
   - Installs all prerequisites on EC2
   - Run this on your EC2 instance

## 🚀 Quick Start (3 Main Steps)

### Step 1: Prepare Your Repository

```bash
# Update Jenkinsfile-EC2 with your GitHub username
# Line 34 in Jenkinsfile-EC2:
REPO_URL = 'github.com/YOUR-USERNAME/aks_data_structures.git'

# Commit and push
git add Jenkinsfile-EC2
git commit -m "Add EC2 Jenkins pipeline"
git push origin main
```

### Step 2: Set Up EC2

```bash
# 1. Launch EC2 instance (t3.medium, Ubuntu 22.04, 30GB storage)
# 2. Configure security group (ports: 22, 8080, 32080)
# 3. SSH into EC2
ssh -i your-key.pem ubuntu@<EC2-IP>

# 4. Run setup script
wget https://raw.githubusercontent.com/YOUR-USERNAME/aks_data_structures/main/jenkins/setup-ec2-jenkins.sh
chmod +x setup-ec2-jenkins.sh
./setup-ec2-jenkins.sh

# 5. Log out and back in
exit
ssh -i your-key.pem ubuntu@<EC2-IP>

# 6. Start Minikube
minikube start --driver=docker --memory=4096 --cpus=2
```

### Step 3: Configure Jenkins

```bash
# 1. Access Jenkins: http://<EC2-IP>:8080
# 2. Get password: cat ~/.jenkins/secrets/initialAdminPassword
# 3. Install suggested plugins
# 4. Create admin user
# 5. Add credentials (Manage Jenkins → Manage Credentials):
#    - github-pat-token (Secret text): Your GitHub PAT
#    - ec2-ssh-key (SSH key): Username=ubuntu, Private key=.pem content
#    - ec2-host-ip (Secret text): Your EC2 public IP
# 6. Create pipeline job:
#    - New Item → Pipeline → Name: aks-data-structures-deployment
#    - GitHub project: https://github.com/YOUR-USERNAME/aks_data_structures
#    - Build Triggers: GitHub hook trigger
#    - Pipeline from SCM: Git, your repo URL, Credentials: github-pat-token
#    - Script Path: Jenkinsfile-EC2
# 7. Build Now!
```

## 🔑 Required Information

Before starting, gather:

| Item | Description | Where to Get |
|------|-------------|--------------|
| **EC2 Public IP** | Your EC2 instance IP | AWS EC2 Console |
| **SSH Key (.pem)** | EC2 SSH private key | Downloaded when creating EC2 |
| **GitHub PAT** | Personal Access Token | GitHub → Settings → Developer settings → PAT |
| **GitHub Username** | Your GitHub username | Your GitHub profile |
| **Repository URL** | Your repo URL | GitHub repository page |

## 📋 Jenkins Credentials Setup

You need to create 3 credentials in Jenkins:

### 1. GitHub PAT Token
- **ID**: `github-pat-token`
- **Type**: Secret text
- **Value**: Your GitHub Personal Access Token
- **How to create PAT**: GitHub → Settings → Developer settings → Personal access tokens → Generate new token (classic) → Select `repo` and `workflow` scopes

### 2. EC2 SSH Key
- **ID**: `ec2-ssh-key`
- **Type**: SSH Username with private key
- **Username**: `ubuntu`
- **Private Key**: Paste content of your .pem file

### 3. EC2 Host IP
- **ID**: `ec2-host-ip`
- **Type**: Secret text
- **Value**: Your EC2 public IP address

## 🏗️ Architecture Overview

```
Developer
    ↓ (git push)
GitHub Repository
    ↓ (webhook)
Jenkins on EC2
    ↓ (SSH)
EC2 Instance
    ├─ Clone/Pull Repository (using GitHub PAT)
    ├─ Start Minikube
    ├─ Build Docker Images (5 services)
    ├─ Deploy with Terraform
    └─ Verify Deployment
        ↓
Application Running on Minikube
    ├─ Stack Service (C)
    ├─ LinkedList Service (Java)
    ├─ Graph Service (Python)
    ├─ Backend Service (Python)
    └─ UI Service (HTML/JS)
```

## 📊 Pipeline Stages

The `Jenkinsfile-EC2` pipeline executes these stages:

1. **Checkout & Clone to EC2**
   - SSH into EC2
   - Clone repository using GitHub PAT
   - Or pull latest changes if already cloned

2. **Ensure Minikube is Running**
   - Check Minikube status
   - Start if not running
   - Verify kubectl access

3. **Build Docker Images**
   - Point Docker to Minikube daemon
   - Build all 5 service images
   - Verify images built successfully

4. **Deploy with Terraform**
   - Run terraform init
   - Run terraform apply
   - Deploy all Kubernetes manifests

5. **Verify Deployment**
   - Wait for pods to be ready
   - Display pod/service status
   - Show access URLs

6. **Optional Port-Forward** (if enabled)
   - Set up port forwarding for services

## 🔒 Security Group Configuration

Your EC2 security group needs these inbound rules:

| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 22 | TCP | Your IP | SSH access |
| 8080 | TCP | 0.0.0.0/0 | Jenkins UI |
| 32080 | TCP | 0.0.0.0/0 | Application UI (NodePort) |
| 5000 | TCP | 0.0.0.0/0 | Backend API (optional) |
| 8081 | TCP | 0.0.0.0/0 | Port-forward (optional) |

## 🌐 Access URLs

After successful deployment:

- **Jenkins**: `http://<EC2-IP>:8080`
- **Application UI**: `http://<EC2-IP>:32080/`
- **Backend API**: `http://<EC2-IP>:32080/api/dashboard`

## 🔄 GitHub Webhook (Optional)

Enable automatic deployment on every push:

1. GitHub Repository → Settings → Webhooks → Add webhook
2. **Payload URL**: `http://<EC2-IP>:8080/github-webhook/`
3. **Content type**: `application/json`
4. **Events**: Just the push event
5. **Active**: ✅

Now every `git push` will automatically trigger Jenkins!

## 🛠️ Troubleshooting

### Common Issues

**Issue**: Cannot access Jenkins on port 8080
```bash
# Check Jenkins status
sudo systemctl status jenkins

# Check if port is open
sudo netstat -tulpn | grep 8080

# Check security group allows port 8080
```

**Issue**: Pipeline fails at SSH stage
```bash
# Verify SSH key is correct in Jenkins credentials
# Test SSH manually
ssh -i your-key.pem ubuntu@<EC2-IP>
```

**Issue**: Docker permission denied
```bash
# On EC2, ensure user is in docker group
groups ubuntu | grep docker

# If not, add and re-login
sudo usermod -aG docker ubuntu
exit
# SSH back in
```

**Issue**: Minikube won't start
```bash
# On EC2
minikube delete
minikube start --driver=docker --memory=4096 --cpus=2
```

**Issue**: Pods stuck in ImagePullBackOff
```bash
# On EC2, rebuild images
cd ~/aks_data_structures
eval $(minikube docker-env)
docker build -t stack-service:latest ./stack
docker build -t linkedlist-service:latest ./linkedlist
docker build -t graph-service:latest ./graph
docker build -t backend-service:latest ./backend
docker build -t ui-service:latest ./ui
```

## 📖 Detailed Documentation

For more detailed information, refer to:

- **`jenkins/EC2_JENKINS_SETUP_GUIDE.md`** - Complete step-by-step guide
- **`jenkins/EC2_QUICK_REFERENCE.md`** - Quick reference card
- **`jenkins/DEPLOYMENT_CHECKLIST.md`** - Interactive checklist
- **`jenkins/EC2_SETUP.md`** - Original EC2 setup guide
- **`jenkins/README.md`** - Jenkins overview

## ✅ Verification Steps

After deployment, verify everything works:

```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@<EC2-IP>

# Check Minikube
minikube status

# Check pods
kubectl get pods
# All should show STATUS: Running

# Check services
kubectl get services

# Test application
curl http://$(minikube ip):32080/
curl http://$(minikube ip):32080/api/dashboard
```

From your browser:
- Open `http://<EC2-IP>:32080/`
- Click "Fetch Data"
- Verify data from all services displays

## 🎯 Next Steps

After successful deployment:

1. ✅ Test the application thoroughly
2. ✅ Set up GitHub webhook for auto-deployment
3. ✅ Configure monitoring (CloudWatch, Prometheus)
4. ✅ Set up SSL/TLS with Let's Encrypt
5. ✅ Configure domain name with Route 53
6. ✅ Add automated testing stages
7. ✅ Set up backup strategy
8. ✅ Configure alerts and notifications

## 💡 Tips

- **Cost Optimization**: Use EC2 Spot Instances for non-production
- **Monitoring**: Set up CloudWatch alarms for EC2 metrics
- **Backups**: Regularly backup Jenkins home directory
- **Security**: Restrict security group to specific IPs in production
- **Scaling**: Consider using EKS for production workloads

## 📞 Support

If you encounter issues:

1. Check Jenkins console output for detailed errors
2. Review EC2 system logs: `sudo journalctl -u jenkins -f`
3. Check Kubernetes resources: `kubectl get all`
4. Review pod logs: `kubectl logs <pod-name>`
5. Consult the troubleshooting section in `EC2_JENKINS_SETUP_GUIDE.md`

## 🎉 Success!

Once everything is working:
- Your application is deployed on EC2
- Jenkins automates the deployment process
- Every git push can trigger automatic deployment
- Your microservices are running on Kubernetes (Minikube)

**Application URL**: `http://<EC2-IP>:32080/`

---

**Ready to deploy?** Start with `jenkins/EC2_JENKINS_SETUP_GUIDE.md` for detailed instructions!
