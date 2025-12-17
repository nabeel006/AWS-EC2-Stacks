# Complete EC2 Jenkins Setup Guide for AKS Data Structures Project

This guide will help you deploy your microservices application on an EC2 instance using Jenkins CI/CD pipeline.

## 📋 Prerequisites

- AWS Account with EC2 access
- GitHub repository with your code
- GitHub Personal Access Token (PAT)
- SSH key pair for EC2 access

## 🚀 Part 1: EC2 Instance Setup

### Step 1: Launch EC2 Instance

1. **Go to AWS EC2 Console** → Launch Instance

2. **Configure Instance:**
   - **Name**: `jenkins-minikube-server`
   - **AMI**: Ubuntu 22.04 LTS
   - **Instance Type**: `t3.medium` (minimum) or `t3.large` (recommended)
     - 2 vCPU, 4 GB RAM minimum
     - 4 vCPU, 8 GB RAM recommended for better performance
   - **Storage**: 30 GB gp3 (minimum)

3. **Configure Security Group:**
   ```
   Type            Protocol    Port Range    Source          Description
   SSH             TCP         22            Your IP         SSH access
   Custom TCP      TCP         8080          0.0.0.0/0       Jenkins UI
   Custom TCP      TCP         32080         0.0.0.0/0       Application UI
   Custom TCP      TCP         5000          0.0.0.0/0       Backend API (optional)
   Custom TCP      TCP         8081          0.0.0.0/0       Port-forward (optional)
   ```

4. **Create/Select Key Pair** and download the `.pem` file

5. **Launch Instance**

### Step 2: Connect to EC2

```bash
# Set proper permissions for your key
chmod 400 your-key.pem

# Connect to EC2
ssh -i your-key.pem ubuntu@<EC2-PUBLIC-IP>
```

### Step 3: Install All Prerequisites on EC2

Run these commands on your EC2 instance:

#### 3.1: Update System
```bash
sudo apt-get update
sudo apt-get upgrade -y
```

#### 3.2: Install Java (Required for Jenkins)
```bash
sudo apt-get install -y openjdk-17-jdk
java -version
```

#### 3.3: Install Docker
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# IMPORTANT: Log out and back in for group changes to take effect
exit
```

**SSH back in:**
```bash
ssh -i your-key.pem ubuntu@<EC2-PUBLIC-IP>
```

**Verify Docker:**
```bash
docker ps
# Should work without sudo
```

#### 3.4: Install Minikube
```bash
# Download and install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

# Verify installation
minikube version
```

#### 3.5: Install kubectl
```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Verify installation
kubectl version --client
```

#### 3.6: Install Terraform
```bash
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Terraform
sudo apt-get update
sudo apt-get install -y terraform

# Verify installation
terraform version
```

#### 3.7: Install Git
```bash
sudo apt-get install -y git
git --version
```

#### 3.8: Start Minikube
```bash
# Start Minikube with Docker driver
minikube start --driver=docker --memory=4096 --cpus=2

# Verify Minikube is running
minikube status

# Verify kubectl can access the cluster
kubectl cluster-info
kubectl get nodes
```

## 🔧 Part 2: Jenkins Installation on EC2

### Step 1: Install Jenkins

```bash
# Download Jenkins WAR file
sudo mkdir -p /opt/jenkins
cd /opt/jenkins
sudo wget https://get.jenkins.io/war-stable/latest/jenkins.war

# Change ownership to ubuntu user
sudo chown -R ubuntu:ubuntu /opt/jenkins
```

### Step 2: Create Jenkins Systemd Service

```bash
sudo tee /etc/systemd/system/jenkins.service > /dev/null <<'EOF'
[Unit]
Description=Jenkins Automation Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/jenkins
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
ExecStart=/usr/bin/java -jar /opt/jenkins/jenkins.war --httpPort=8080
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
```

### Step 3: Start Jenkins

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable Jenkins to start on boot
sudo systemctl enable jenkins

# Start Jenkins
sudo systemctl start jenkins

# Check status
sudo systemctl status jenkins
```

### Step 4: Get Jenkins Initial Password

```bash
# Wait for Jenkins to start (about 1-2 minutes)
sleep 60

# Get initial admin password
cat ~/.jenkins/secrets/initialAdminPassword
```

**Copy this password - you'll need it in the next step!**

## 🌐 Part 3: Jenkins Configuration

### Step 1: Access Jenkins

1. Open browser: `http://<EC2-PUBLIC-IP>:8080`
2. Paste the initial admin password
3. Click **Continue**

### Step 2: Install Plugins

1. Select **Install suggested plugins**
2. Wait for plugins to install
3. Additionally install these plugins:
   - Go to **Manage Jenkins** → **Manage Plugins** → **Available**
   - Search and install:
     - ✅ **SSH Agent Plugin**
     - ✅ **GitHub Plugin**
     - ✅ **Pipeline Plugin** (should already be installed)
     - ✅ **Git Plugin** (should already be installed)
     - ✅ **Credentials Binding Plugin** (should already be installed)

### Step 3: Create Admin User

1. Fill in admin user details:
   - Username: `admin`
   - Password: (choose a strong password)
   - Full name: Your name
   - Email: Your email
2. Click **Save and Continue**
3. Click **Save and Finish**
4. Click **Start using Jenkins**

## 🔐 Part 4: Configure Jenkins Credentials

### Step 1: Add GitHub PAT Token

1. Go to **Manage Jenkins** → **Manage Credentials**
2. Click **(global)** domain
3. Click **Add Credentials**
4. Configure:
   - **Kind**: Secret text
   - **Scope**: Global
   - **Secret**: (paste your GitHub Personal Access Token)
   - **ID**: `github-pat-token`
   - **Description**: GitHub PAT for repository access
5. Click **Create**

**How to create GitHub PAT:**
- Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
- Click **Generate new token (classic)**
- Select scopes: `repo` (all), `workflow`
- Copy the token immediately (you won't see it again!)

### Step 2: Add EC2 SSH Key

1. Go to **Manage Jenkins** → **Manage Credentials**
2. Click **(global)** domain
3. Click **Add Credentials**
4. Configure:
   - **Kind**: SSH Username with private key
   - **Scope**: Global
   - **ID**: `ec2-ssh-key`
   - **Description**: EC2 SSH Key
   - **Username**: `ubuntu`
   - **Private Key**: Click **Enter directly**
     - Paste your EC2 private key content (the .pem file)
5. Click **Create**

### Step 3: Add EC2 Host IP

1. Go to **Manage Jenkins** → **Manage Credentials**
2. Click **(global)** domain
3. Click **Add Credentials**
4. Configure:
   - **Kind**: Secret text
   - **Scope**: Global
   - **Secret**: (paste your EC2 public IP)
   - **ID**: `ec2-host-ip`
   - **Description**: EC2 Host IP Address
5. Click **Create**

## 📦 Part 5: Create Jenkins Pipeline

### Step 1: Create New Pipeline Job

1. Click **New Item**
2. Enter name: `aks-data-structures-deployment`
3. Select **Pipeline**
4. Click **OK**

### Step 2: Configure Pipeline

1. **General Section:**
   - ✅ Check **GitHub project**
   - Project url: `https://github.com/YOUR-USERNAME/aks_data_structures/`

2. **Build Triggers:**
   - ✅ Check **GitHub hook trigger for GITScm polling**

3. **Pipeline Section:**
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: `https://github.com/YOUR-USERNAME/aks_data_structures.git`
   - **Credentials**: Select `github-pat-token`
   - **Branch Specifier**: `*/main` (or your branch name)
   - **Script Path**: `Jenkinsfile-EC2`

4. Click **Save**

### Step 3: Update Jenkinsfile-EC2

Before running the pipeline, update the `Jenkinsfile-EC2` in your repository:

```groovy
environment {
    // Update this line with your actual GitHub repository
    REPO_URL = 'github.com/YOUR-USERNAME/aks_data_structures.git'
    
    // Rest remains the same...
}
```

Commit and push this change to your repository.

## 🎯 Part 6: Test the Pipeline

### Step 1: Manual Build

1. Go to your pipeline job
2. Click **Build with Parameters**
3. Leave defaults:
   - ENABLE_PORT_FORWARD: false
   - MINIKUBE_PROFILE: minikube
   - TERRAFORM_WORKSPACE: local
4. Click **Build**

### Step 2: Monitor Build

1. Click on the build number (e.g., #1)
2. Click **Console Output**
3. Watch the pipeline execute:
   - ✅ Clone repository to EC2
   - ✅ Ensure Minikube is running
   - ✅ Build Docker images
   - ✅ Deploy with Terraform
   - ✅ Verify deployment

### Step 3: Access Application

Once the build succeeds, you'll see output like:
```
Access URLs:
Web UI:      http://<EC2-IP>:32080/
Backend API: http://<EC2-IP>:32080/api/dashboard
```

Open `http://<EC2-PUBLIC-IP>:32080/` in your browser!

## 🔗 Part 7: Configure GitHub Webhook (Optional)

This enables automatic deployment on every git push.

### Step 1: Get Jenkins Webhook URL

Your webhook URL is: `http://<EC2-PUBLIC-IP>:8080/github-webhook/`

### Step 2: Configure in GitHub

1. Go to your GitHub repository
2. Click **Settings** → **Webhooks** → **Add webhook**
3. Configure:
   - **Payload URL**: `http://<EC2-PUBLIC-IP>:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Which events**: Just the push event
   - **Active**: ✅
4. Click **Add webhook**

### Step 3: Test Webhook

1. Make a small change to your repository
2. Commit and push
3. Jenkins should automatically trigger a build!

## 🔍 Part 8: Verification & Testing

### Verify Deployment on EC2

SSH into your EC2 instance and run:

```bash
# Check Minikube status
minikube status

# Check pods
kubectl get pods

# Check services
kubectl get services

# Check deployments
kubectl get deployments

# Get Minikube IP
minikube ip
```

### Test Application

```bash
# Get EC2 public IP
curl http://169.254.169.254/latest/meta-data/public-ipv4

# Test UI
curl http://<EC2-IP>:32080/

# Test Backend API
curl http://<EC2-IP>:32080/api/dashboard
```

### Access from Browser

Open in your browser:
- **UI**: `http://<EC2-PUBLIC-IP>:32080/`
- **Backend**: `http://<EC2-PUBLIC-IP>:32080/api/dashboard`

## 🛠️ Troubleshooting

### Issue 1: Jenkins won't start

```bash
# Check Jenkins logs
sudo journalctl -u jenkins -n 50 -f

# Restart Jenkins
sudo systemctl restart jenkins
```

### Issue 2: Cannot access Jenkins on port 8080

**Solution:**
- Check EC2 security group allows port 8080
- Check if Jenkins is running: `sudo systemctl status jenkins`
- Check if port is listening: `sudo netstat -tulpn | grep 8080`

### Issue 3: Pipeline fails at SSH stage

**Solution:**
- Verify EC2 SSH key is correctly added to Jenkins credentials
- Test SSH manually: `ssh -i your-key.pem ubuntu@<EC2-IP>`
- Check Jenkins console output for specific error

### Issue 4: Minikube fails to start

```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@<EC2-IP>

# Check Docker
docker ps

# Delete and restart Minikube
minikube delete
minikube start --driver=docker --memory=4096 --cpus=2
```

### Issue 5: Docker build fails

```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@<EC2-IP>

# Point Docker to Minikube
eval $(minikube docker-env)

# Verify
docker ps
```

### Issue 6: Cannot access application on port 32080

**Solution:**
- Check EC2 security group allows port 32080
- Verify ingress is running: `kubectl get pods -n ingress-nginx`
- Check service: `kubectl get svc`

### Issue 7: Pods stuck in Pending/ImagePullBackOff

```bash
# SSH into EC2
kubectl get pods
kubectl describe pod <pod-name>

# Rebuild images
cd ~/aks_data_structures
eval $(minikube docker-env)
docker build -t stack-service:latest ./stack
# ... build other services
```

## 📊 Monitoring & Maintenance

### View Jenkins Logs

```bash
# On EC2
sudo journalctl -u jenkins -f
```

### View Application Logs

```bash
# SSH into EC2
kubectl logs -f deployment/backend-deployment
kubectl logs -f deployment/ui-deployment
```

### Restart Services

```bash
# Restart Jenkins
sudo systemctl restart jenkins

# Restart Minikube
minikube stop
minikube start

# Restart specific deployment
kubectl rollout restart deployment/backend-deployment
```

### Clean Up Resources

```bash
# Delete all Kubernetes resources
kubectl delete -f ~/aks_data_structures/k8s/

# Or use Terraform
cd ~/aks_data_structures/terraform/local
terraform destroy -auto-approve
```

## 🎓 Next Steps

1. ✅ Set up SSL/TLS with Let's Encrypt
2. ✅ Configure domain name with Route 53
3. ✅ Set up monitoring (CloudWatch, Prometheus)
4. ✅ Configure automated backups
5. ✅ Add more stages to pipeline (testing, security scanning)
6. ✅ Set up multiple environments (dev, staging, prod)

## 📝 Summary

You now have:
- ✅ EC2 instance with all prerequisites installed
- ✅ Jenkins running on EC2
- ✅ Minikube cluster on EC2
- ✅ Automated CI/CD pipeline
- ✅ GitHub webhook integration
- ✅ Microservices application deployed

Your application is accessible at: `http://<EC2-PUBLIC-IP>:32080/`

## 🆘 Need Help?

Check the console output in Jenkins for detailed error messages. Most issues are related to:
1. Missing credentials in Jenkins
2. Security group configuration
3. Minikube not running
4. Docker not pointing to Minikube

---

**Congratulations! Your Jenkins CI/CD pipeline is now running on EC2!** 🎉
