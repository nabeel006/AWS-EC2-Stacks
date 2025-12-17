# 🚀 START HERE - Deploy to EC2 with Jenkins

## What I've Created for You

I've analyzed your complete project and created a comprehensive Jenkins CI/CD pipeline for deploying your microservices application to AWS EC2. Here's everything you need to know:

## 📦 Your Project

**AKS Data Structures** - A microservices application with:
- 5 services: Stack (C), LinkedList (Java), Graph (Python), Backend (Python), UI (HTML/JS)
- Kubernetes deployment using Terraform
- Currently working on your local machine with Minikube

## 🎯 What's New

I've created **6 new files** to enable EC2 deployment:

### 1. **Jenkinsfile-EC2** (Root directory)
The Jenkins pipeline that will deploy your app on EC2.

**⚠️ ACTION REQUIRED**: Update line 34 with your GitHub username:
```groovy
REPO_URL = 'github.com/YOUR-USERNAME/aks_data_structures.git'
```

### 2. **DEPLOY_TO_EC2.md** (Root directory)
Main overview document - start here for understanding the architecture.

### 3. **jenkins/EC2_JENKINS_SETUP_GUIDE.md**
Complete step-by-step guide with detailed instructions (MOST DETAILED).

### 4. **jenkins/EC2_QUICK_REFERENCE.md**
Quick reference card for experienced users.

### 5. **jenkins/DEPLOYMENT_CHECKLIST.md**
Interactive checklist to track your deployment progress.

### 6. **jenkins/setup-ec2-jenkins.sh**
Automated script to install everything on EC2.

## 🏁 Quick Start (3 Steps)

### Step 1: Update Your Repository (5 minutes)

```bash
# 1. Update Jenkinsfile-EC2 with your GitHub username
# Edit line 34: REPO_URL = 'github.com/YOUR-USERNAME/aks_data_structures.git'

# 2. Commit and push
git add .
git commit -m "Add EC2 Jenkins deployment"
git push origin main
```

### Step 2: Set Up EC2 (30 minutes)

```bash
# 1. Launch EC2 instance on AWS
#    - Type: t3.medium (minimum)
#    - OS: Ubuntu 22.04 LTS
#    - Storage: 30 GB
#    - Security Group: Ports 22, 8080, 32080

# 2. SSH into EC2
ssh -i your-key.pem ubuntu@<EC2-IP>

# 3. Download and run setup script
wget https://raw.githubusercontent.com/YOUR-USERNAME/aks_data_structures/main/jenkins/setup-ec2-jenkins.sh
chmod +x setup-ec2-jenkins.sh
./setup-ec2-jenkins.sh

# 4. Log out and back in (for Docker group)
exit
ssh -i your-key.pem ubuntu@<EC2-IP>

# 5. Start Minikube
minikube start --driver=docker --memory=4096 --cpus=2
```

### Step 3: Configure Jenkins (15 minutes)

```bash
# 1. Access Jenkins: http://<EC2-IP>:8080
# 2. Get password: cat ~/.jenkins/secrets/initialAdminPassword
# 3. Install suggested plugins
# 4. Create admin user
# 5. Add 3 credentials in Jenkins (Manage Jenkins → Manage Credentials):
#    a) github-pat-token (Secret text) - Your GitHub PAT
#    b) ec2-ssh-key (SSH key) - Username: ubuntu, Key: .pem content
#    c) ec2-host-ip (Secret text) - Your EC2 public IP
# 6. Create pipeline job:
#    - New Item → Pipeline → Name: aks-data-structures-deployment
#    - GitHub project URL
#    - Build Triggers: GitHub hook trigger
#    - Pipeline from SCM: Git, your repo, Credentials: github-pat-token
#    - Script Path: Jenkinsfile-EC2
# 7. Click "Build Now"!
```

## 🔑 What You Need

Before starting, gather:

1. **AWS Account** - To launch EC2 instance
2. **GitHub PAT Token** - Create at: GitHub → Settings → Developer settings → Personal access tokens
   - Scopes needed: `repo`, `workflow`
3. **EC2 SSH Key** - Download when creating EC2 instance (.pem file)
4. **Your GitHub Username** - To update Jenkinsfile-EC2

## 📚 Which Guide to Follow?

### First Time? → Follow This Path:
1. Read **`DEPLOY_TO_EC2.md`** (10 min) - Get overview
2. Follow **`jenkins/EC2_JENKINS_SETUP_GUIDE.md`** (45 min) - Detailed steps
3. Use **`jenkins/DEPLOYMENT_CHECKLIST.md`** - Track progress

### Experienced? → Quick Path:
1. Use **`jenkins/EC2_QUICK_REFERENCE.md`** (5 min)
2. Run **`setup-ec2-jenkins.sh`** on EC2
3. Configure Jenkins and deploy

## 🎯 After Deployment

Your application will be accessible at:
- **Jenkins**: `http://<EC2-IP>:8080`
- **Application UI**: `http://<EC2-IP>:32080/`
- **Backend API**: `http://<EC2-IP>:32080/api/dashboard`

## 🔄 How It Works

```
You push code to GitHub
        ↓
Jenkins detects change (webhook)
        ↓
Jenkins SSHs into EC2
        ↓
Clones/pulls your repo (using GitHub PAT)
        ↓
Builds Docker images (5 services)
        ↓
Deploys to Minikube using Terraform
        ↓
Application is live! 🎉
```

## ✅ Success Checklist

After following the guides, you should have:
- [ ] EC2 instance running
- [ ] Jenkins accessible
- [ ] Pipeline configured
- [ ] First build successful
- [ ] Application accessible at `http://<EC2-IP>:32080`
- [ ] All 5 microservices running

## 🆘 Need Help?

**Common Issues:**
- Can't access Jenkins? → Check security group allows port 8080
- Pipeline fails? → Check Jenkins console output for errors
- Docker issues? → Ensure you logged out/in after setup script
- Minikube won't start? → Run: `minikube delete && minikube start`

**Detailed Help:**
- Troubleshooting: See `jenkins/EC2_JENKINS_SETUP_GUIDE.md` Part 8
- Quick fixes: See `jenkins/EC2_QUICK_REFERENCE.md`

## 📖 All Documentation

| File | Purpose | When to Use |
|------|---------|-------------|
| `START_HERE_EC2.md` | This file - Quick overview | Start here |
| `DEPLOY_TO_EC2.md` | Architecture & overview | Understanding system |
| `jenkins/EC2_JENKINS_SETUP_GUIDE.md` | Complete step-by-step | First-time setup |
| `jenkins/EC2_QUICK_REFERENCE.md` | Quick reference | Experienced users |
| `jenkins/DEPLOYMENT_CHECKLIST.md` | Interactive checklist | Track progress |
| `jenkins/setup-ec2-jenkins.sh` | Automated installer | Run on EC2 |
| `Jenkinsfile-EC2` | Pipeline definition | Used by Jenkins |

## 🎓 Next Steps After Deployment

1. ✅ Test the application thoroughly
2. ✅ Set up GitHub webhook for auto-deployment
3. ✅ Configure monitoring
4. ✅ Set up SSL/TLS
5. ✅ Add automated testing

## 💡 Pro Tips

- **Save your GitHub PAT** - You'll need it for Jenkins credentials
- **Document your EC2 IP** - You'll use it multiple times
- **Keep your .pem file safe** - Required for SSH access
- **Use the checklist** - Ensures you don't miss any steps

## 🚦 Ready to Start?

1. **Update** `Jenkinsfile-EC2` with your GitHub username
2. **Commit and push** to GitHub
3. **Follow** `jenkins/EC2_JENKINS_SETUP_GUIDE.md`
4. **Deploy** your application!

---

**Estimated Total Time**: 1 hour (first time), 20 minutes (subsequent deployments)

**Your application works locally** ✅  
**Now let's deploy it to EC2!** 🚀

---

**Questions?** Check the detailed guides or troubleshooting sections.
**Ready?** Start with updating `Jenkinsfile-EC2` and then follow `jenkins/EC2_JENKINS_SETUP_GUIDE.md`!
