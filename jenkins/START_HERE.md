# Jenkins CI/CD Setup - Start Here

## 🚀 Quick Start for Local Setup

### Option 1: Automated Setup (Easiest)

```bash
# Run the setup script
cd jenkins
./setup-local-jenkins.sh
```

The script will:
- ✅ Check all prerequisites
- ✅ Install Jenkins if needed
- ✅ Start Jenkins
- ✅ Get initial admin password
- ✅ Check Minikube status

### Option 2: Manual Setup

Follow the detailed guide: **[LOCAL_SETUP.md](LOCAL_SETUP.md)**

## 📋 What You'll Need

Before starting, ensure you have:

- ✅ macOS (for local setup)
- ✅ Homebrew installed
- ✅ Minikube installed (`brew install minikube`)
- ✅ kubectl installed (`brew install kubectl`)
- ✅ Terraform installed (`brew install terraform`)
- ✅ Docker installed (Docker Desktop)
- ✅ Git installed

## 🎯 Setup Steps Summary

1. **Install Jenkins** (via script or manually)
2. **Access Jenkins** at `http://localhost:8080`
3. **Get admin password** (shown by script or in `~/.jenkins/secrets/initialAdminPassword`)
4. **Install plugins**: GitHub, Pipeline, Docker Pipeline
5. **Create pipeline job** pointing to your GitHub repo
6. **Configure GitHub webhook** (optional, for auto-trigger)
7. **Test pipeline** with "Build Now"

## 📚 Documentation

- **[LOCAL_SETUP.md](LOCAL_SETUP.md)** - Detailed local setup guide
- **[EC2_SETUP.md](EC2_SETUP.md)** - EC2 deployment guide (for later)
- **[QUICK_START.md](QUICK_START.md)** - Quick reference
- **[JENKINS_SETUP.md](JENKINS_SETUP.md)** - Comprehensive setup guide
- **[README.md](README.md)** - Overview and architecture

## 🔄 Typical Workflow

```
1. Make code changes
2. Git push to GitHub
3. GitHub webhook triggers Jenkins
4. Jenkins pipeline runs:
   - Builds Docker images
   - Deploys to Minikube
   - Verifies deployment
5. Access application at http://<minikube-ip>:32080
```

## 🆘 Need Help?

### Common Issues

**Jenkins won't start?**
```bash
brew services restart jenkins-lts
tail -f ~/.jenkins/logs/jenkins.log
```

**Pipeline fails at Minikube step?**
```bash
minikube start
minikube status
```

**Docker build fails?**
```bash
eval $(minikube docker-env)
docker ps
```

### Get More Help

- Check [LOCAL_SETUP.md](LOCAL_SETUP.md) troubleshooting section
- Check Jenkins logs: `tail -f ~/.jenkins/logs/jenkins.log`
- Check pipeline console output in Jenkins UI

## 🎓 Next Steps After Local Setup

Once local setup is working:

1. ✅ Test pipeline multiple times
2. ✅ Verify all services deploy correctly
3. ✅ Test GitHub webhook
4. 📋 Prepare for EC2 deployment (see [EC2_SETUP.md](EC2_SETUP.md))

## 📞 Quick Commands

```bash
# Start Jenkins
brew services start jenkins-lts

# Stop Jenkins
brew services stop jenkins-lts

# View Jenkins logs
tail -f ~/.jenkins/logs/jenkins.log

# Check Minikube
minikube status

# Start Minikube
minikube start

# Access Jenkins
open http://localhost:8080
```

---

**Ready to start?** Run `./setup-local-jenkins.sh` or follow [LOCAL_SETUP.md](LOCAL_SETUP.md)

