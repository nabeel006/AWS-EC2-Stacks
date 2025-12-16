# Local Jenkins Setup Guide

This guide will help you set up Jenkins locally on your Mac to test the CI/CD pipeline before deploying to EC2.

## Prerequisites

Before starting, ensure you have:

```bash
# Check all prerequisites
minikube version
kubectl version --client
terraform version
docker --version
git --version
```

If any are missing, install them:

```bash
# Install via Homebrew
brew install minikube kubectl terraform docker
```

## Step 1: Install Jenkins Locally

### Option A: Using Homebrew (Recommended)

```bash
# Install Jenkins LTS
brew install jenkins-lts

# Start Jenkins
brew services start jenkins-lts

# Check status
brew services list | grep jenkins
```

### Option B: Using Docker

```bash
# Run Jenkins in Docker
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts

# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### Option C: Download Jenkins WAR File

```bash
# Download Jenkins
curl -L https://get.jenkins.io/war-stable/latest/jenkins.war -o jenkins.war

# Run Jenkins
java -jar jenkins.war --httpPort=8080
```

**We recommend Option A (Homebrew) for easiest local setup.**

## Step 2: Access Jenkins

1. **Open Jenkins in browser:**
   ```
   http://localhost:8080
   ```

2. **Get initial admin password:**
   ```bash
   # For Homebrew installation
   cat ~/.jenkins/secrets/initialAdminPassword
   
   # For Docker installation
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   
   # For WAR file
   # Password is shown in terminal output
   ```

3. **Complete initial setup:**
   - Enter the admin password
   - Install suggested plugins (or select specific plugins)
   - Create admin user (or skip to use admin account)
   - Save and finish

## Step 3: Install Required Jenkins Plugins

1. Go to: **Manage Jenkins** → **Manage Plugins** → **Available**

2. Search and install these plugins:
   - **GitHub plugin** (for webhook support)
   - **Pipeline** (for Jenkinsfile support)
   - **Docker Pipeline** (for Docker operations)
   - **Git** (for Git operations)

3. Click **Install without restart** or **Download now and install after restart**

4. Restart Jenkins if prompted:
   ```bash
   # For Homebrew
   brew services restart jenkins-lts
   
   # For Docker
   docker restart jenkins
   ```

## Step 4: Configure Jenkins for Local Development

### 4.1: Configure Git (if needed)

1. Go to: **Manage Jenkins** → **Configure System**
2. Under **Git**, ensure Git executable path is correct:
   - Usually: `/usr/bin/git` or `/usr/local/bin/git`
   - Check with: `which git`

### 4.2: Configure Docker (if using Docker plugin)

1. Go to: **Manage Jenkins** → **Configure System**
2. Under **Docker**, configure Docker installation:
   - Docker URL: `unix:///var/run/docker.sock` (for local Docker)
   - Or leave default if using Minikube Docker

### 4.3: Ensure Tools are Accessible

Jenkins needs access to these tools. Verify they're in PATH:

```bash
# Check if tools are accessible
which minikube
which kubectl
which terraform
which docker
which git

# If any are missing, add to PATH in Jenkins
# Go to: Manage Jenkins → Configure System → Global properties
# Add: Environment variables
# PATH: /usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin
```

## Step 5: Create Jenkins Pipeline

1. **Create New Pipeline:**
   - Click **New Item**
   - Enter name: `aks-data-structures-pipeline`
   - Select **Pipeline**
   - Click **OK**

2. **Configure Pipeline:**
   - Scroll to **Pipeline** section
   - **Definition**: Select **Pipeline script from SCM**
   - **SCM**: Select **Git**
   - **Repository URL**: Enter your GitHub repository URL
     - Example: `https://github.com/yourusername/aks_data_structures.git`
   - **Credentials**: Add credentials if repository is private
   - **Branch**: `*/main` (or your default branch)
   - **Script Path**: `Jenkinsfile`
   - Click **Save**

## Step 6: Test Pipeline Manually

1. **Start Minikube (if not running):**
   ```bash
   minikube start
   ```

2. **Trigger Pipeline:**
   - Go to your pipeline in Jenkins
   - Click **Build Now**
   - Watch the build progress

3. **Check Build Logs:**
   - Click on the build number
   - Click **Console Output**
   - Monitor each stage

## Step 7: Configure GitHub Webhook (Optional for Auto-trigger)

If you want automatic builds on Git push:

1. **Get your local IP:**
   ```bash
   # macOS
   ipconfig getifaddr en0
   # or
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```

2. **Configure GitHub Webhook:**
   - Go to your GitHub repository
   - **Settings** → **Webhooks** → **Add webhook**
   - **Payload URL**: `http://<your-local-ip>:8080/github-webhook/`
     - Example: `http://192.168.1.100:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Events**: Select **Just the push event**
   - **Active**: ✓
   - Click **Add webhook**

3. **Note:** For webhook to work, your Mac must be accessible from GitHub:
   - If behind firewall/NAT, you may need to use a tunneling service like ngrok
   - Or test manually with "Build Now" button

### Using ngrok for Webhook (if needed)

```bash
# Install ngrok
brew install ngrok

# Start tunnel
ngrok http 8080

# Use the ngrok URL in GitHub webhook
# Example: https://abc123.ngrok.io/github-webhook/
```

## Step 8: Verify Deployment

After pipeline runs successfully:

```bash
# Check pods
kubectl get pods

# Check services
kubectl get services

# Get Minikube IP
minikube ip

# Access application
MINIKUBE_IP=$(minikube ip)
echo "Web UI: http://${MINIKUBE_IP}:32080/"
echo "API: http://${MINIKUBE_IP}:32080/api/dashboard"
```

## Troubleshooting

### Issue: Jenkins can't find minikube/kubectl/terraform

**Solution:**
- Add tools to Jenkins PATH:
  - Manage Jenkins → Configure System → Global properties
  - Add environment variable: `PATH` with value including tool locations
- Or create symlinks in `/usr/local/bin`

### Issue: Docker build fails

**Solution:**
```bash
# Ensure Docker is pointing to Minikube
eval $(minikube docker-env)

# Verify
docker ps
```

### Issue: Pipeline fails at Minikube stage

**Solution:**
- Ensure Minikube is installed: `which minikube`
- Start Minikube manually: `minikube start`
- Check Minikube status: `minikube status`

### Issue: GitHub webhook not working

**Solution:**
- Test manually with "Build Now" first
- Check Jenkins logs: Manage Jenkins → System Log
- Verify webhook URL is accessible
- Use ngrok for local testing

### Issue: Permission denied errors

**Solution:**
```bash
# Ensure Jenkins user has permissions
# For Homebrew Jenkins, it runs as your user
# For Docker, ensure volumes have correct permissions
```

## Quick Test Script

Create a test script to verify everything works:

```bash
#!/bin/bash
echo "Testing Jenkins Pipeline Prerequisites..."

echo "1. Checking Minikube..."
minikube status || minikube start

echo "2. Checking Docker..."
eval $(minikube docker-env)
docker ps > /dev/null && echo "✓ Docker OK" || echo "✗ Docker failed"

echo "3. Checking kubectl..."
kubectl get nodes > /dev/null && echo "✓ kubectl OK" || echo "✗ kubectl failed"

echo "4. Checking Terraform..."
terraform version > /dev/null && echo "✓ Terraform OK" || echo "✗ Terraform failed"

echo "5. Checking Git..."
git --version > /dev/null && echo "✓ Git OK" || echo "✗ Git failed"

echo "All checks complete!"
```

## Next Steps

Once local setup is working:

1. ✅ Test pipeline multiple times
2. ✅ Verify all services deploy correctly
3. ✅ Test GitHub webhook (if configured)
4. ✅ Document any custom configurations
5. 📋 Prepare for EC2 deployment (see EC2_SETUP.md)

## Useful Commands

```bash
# Start Jenkins
brew services start jenkins-lts

# Stop Jenkins
brew services stop jenkins-lts

# Restart Jenkins
brew services restart jenkins-lts

# View Jenkins logs
tail -f ~/.jenkins/logs/jenkins.log

# Access Jenkins CLI
java -jar ~/.jenkins/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080 help
```

