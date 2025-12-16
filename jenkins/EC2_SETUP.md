# EC2 Deployment Guide for Jenkins

This guide will help you deploy Jenkins and the CI/CD pipeline on an EC2 instance.

## Prerequisites

- AWS Account with EC2 access
- AWS CLI configured (optional but helpful)
- SSH access to EC2 instance
- Basic knowledge of AWS EC2

## Step 1: Launch EC2 Instance

### 1.1: Choose Instance Type

Recommended instance specifications:
- **Instance Type**: `t3.medium` or larger (2 vCPU, 4 GB RAM minimum)
- **OS**: Ubuntu 22.04 LTS or Amazon Linux 2023
- **Storage**: 20 GB minimum (for Jenkins and Docker images)
- **Security Group**: Allow inbound:
  - Port 22 (SSH)
  - Port 8080 (Jenkins)
  - Port 50000 (Jenkins agent communication)

### 1.2: Launch Instance

1. Go to EC2 Console → Launch Instance
2. Select Ubuntu 22.04 LTS AMI
3. Choose instance type (t3.medium recommended)
4. Configure security group:
   ```
   Type        Protocol    Port Range    Source
   SSH         TCP         22            Your IP
   Custom TCP  TCP         8080          0.0.0.0/0 (or your IP)
   Custom TCP  TCP         50000         0.0.0.0/0 (or your IP)
   ```
5. Create or select key pair
6. Launch instance

### 1.3: Connect to Instance

```bash
# Replace with your key and instance details
ssh -i your-key.pem ubuntu@<ec2-public-ip>
```

## Step 2: Install Prerequisites on EC2

Run these commands on your EC2 instance:

### 2.1: Update System

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

### 2.2: Install Java (Required for Jenkins)

```bash
sudo apt-get install -y openjdk-17-jdk
java -version
```

### 2.3: Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose (optional but useful)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Log out and back in for group changes
exit
# SSH back in
```

### 2.4: Install Minikube

```bash
# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Verify installations
minikube version
kubectl version --client
```

### 2.5: Install Terraform

```bash
# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y terraform

terraform version
```

### 2.6: Install Git

```bash
sudo apt-get install -y git
git --version
```

## Step 3: Install Jenkins

### Option A: Using Jenkins WAR File (Recommended for EC2)

```bash
# Create Jenkins directory
sudo mkdir -p /opt/jenkins
cd /opt/jenkins

# Download Jenkins WAR
sudo wget https://get.jenkins.io/war-stable/latest/jenkins.war

# Create systemd service
sudo tee /etc/systemd/system/jenkins.service > /dev/null <<EOF
[Unit]
Description=Jenkins Automation Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/jenkins
ExecStart=/usr/bin/java -jar /opt/jenkins/jenkins.war --httpPort=8080
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start Jenkins
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Check status
sudo systemctl status jenkins
```

### Option B: Using Docker

```bash
# Run Jenkins in Docker
docker run -d \
  --name jenkins \
  --restart=unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

# Get initial password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

## Step 4: Configure Jenkins

### 4.1: Access Jenkins

1. Open browser: `http://<ec2-public-ip>:8080`
2. Get initial password:
   ```bash
   # For WAR installation
   sudo cat /opt/jenkins/secrets/initialAdminPassword
   
   # For Docker installation
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```

### 4.2: Initial Setup

1. Enter admin password
2. Install suggested plugins
3. Create admin user
4. Save and finish

### 4.3: Install Required Plugins

Go to: **Manage Jenkins** → **Manage Plugins** → **Available**

Install:
- GitHub plugin
- Pipeline plugin
- Docker Pipeline plugin
- Git plugin

### 4.4: Configure Tools Path

1. Go to: **Manage Jenkins** → **Configure System**
2. Add global environment variables:
   - `PATH`: `/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin`
   - `DOCKER_HOST`: `unix:///var/run/docker.sock`

## Step 5: Set Up Minikube on EC2

```bash
# Start Minikube with Docker driver
minikube start --driver=docker

# Verify
minikube status
kubectl get nodes

# Configure Docker to use Minikube
eval $(minikube docker-env)
docker ps
```

## Step 6: Create Jenkins Pipeline

1. **New Item** → **Pipeline**
2. Name: `aks-data-structures-pipeline`
3. **Pipeline** → **Definition**: Pipeline script from SCM
4. **SCM**: Git
5. **Repository URL**: Your GitHub repo URL
6. **Credentials**: Add if private repo
7. **Branch**: `*/main`
8. **Script Path**: `Jenkinsfile`
9. **Save**

## Step 7: Configure GitHub Webhook

1. Get your EC2 public IP:
   ```bash
   curl http://169.254.169.254/latest/meta-data/public-ipv4
   ```

2. Configure GitHub webhook:
   - GitHub Repo → **Settings** → **Webhooks** → **Add webhook**
   - **Payload URL**: `http://<ec2-public-ip>:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Events**: Just the push event
   - **Active**: ✓

3. **Important**: Ensure security group allows inbound on port 8080

## Step 8: Test Pipeline

1. Click **Build Now** in Jenkins
2. Monitor build progress
3. Check console output
4. Verify deployment:
   ```bash
   kubectl get pods
   kubectl get services
   ```

## Step 9: Set Up Domain Name (Optional)

### Using Route 53

1. Create A record pointing to EC2 public IP
2. Update security group to allow HTTP/HTTPS
3. Configure Jenkins behind reverse proxy (nginx)

### Using Nginx Reverse Proxy

```bash
# Install nginx
sudo apt-get install -y nginx

# Configure nginx
sudo tee /etc/nginx/sites-available/jenkins > /dev/null <<EOF
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## Step 10: Security Hardening

### 10.1: Set Up SSL/TLS

Use Let's Encrypt with Certbot:

```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

### 10.2: Restrict Security Group

Update security group to only allow:
- Port 22 from your IP
- Port 80/443 from anywhere (if using domain)
- Port 8080 only from GitHub webhook IPs (if possible)

### 10.3: Set Up Firewall

```bash
# Install UFW
sudo apt-get install -y ufw

# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow Jenkins (restrict to specific IPs if possible)
sudo ufw allow 8080/tcp

# Enable firewall
sudo ufw enable
sudo ufw status
```

## Step 11: Backup Jenkins

### 11.1: Backup Jenkins Home Directory

```bash
# Create backup script
sudo tee /opt/jenkins/backup.sh > /dev/null <<'EOF'
#!/bin/bash
BACKUP_DIR="/opt/jenkins/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Backup Jenkins home
tar -czf $BACKUP_DIR/jenkins_backup_$DATE.tar.gz /opt/jenkins/.jenkins

# Keep only last 7 days
find $BACKUP_DIR -name "jenkins_backup_*.tar.gz" -mtime +7 -delete
EOF

sudo chmod +x /opt/jenkins/backup.sh

# Add to crontab (daily backup at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/jenkins/backup.sh") | crontab -
```

### 11.2: Backup to S3 (Optional)

```bash
# Install AWS CLI
sudo apt-get install -y awscli

# Configure AWS credentials
aws configure

# Update backup script to upload to S3
```

## Monitoring and Maintenance

### Check Jenkins Status

```bash
# For WAR installation
sudo systemctl status jenkins

# For Docker installation
docker ps | grep jenkins
```

### View Jenkins Logs

```bash
# For WAR installation
sudo journalctl -u jenkins -f

# For Docker installation
docker logs -f jenkins
```

### Restart Jenkins

```bash
# For WAR installation
sudo systemctl restart jenkins

# For Docker installation
docker restart jenkins
```

## Troubleshooting

### Issue: Cannot access Jenkins on port 8080

**Solution:**
- Check security group rules
- Check firewall: `sudo ufw status`
- Check if Jenkins is running: `sudo systemctl status jenkins`
- Check logs: `sudo journalctl -u jenkins -n 50`

### Issue: Minikube fails to start

**Solution:**
```bash
# Check Docker
docker ps

# Start Minikube with more resources
minikube start --driver=docker --memory=4096 --cpus=2
```

### Issue: GitHub webhook not working

**Solution:**
- Verify security group allows port 8080
- Check Jenkins logs for webhook requests
- Test webhook manually: `curl -X POST http://<ec2-ip>:8080/github-webhook/`

### Issue: Out of disk space

**Solution:**
```bash
# Clean Docker images
docker system prune -a

# Clean Jenkins workspace (be careful!)
# Go to Jenkins → Manage Jenkins → Script Console
# Run: Jenkins.instance.getAllItems(Job.class).each { job -> job.builds.each { it.delete() } }
```

## Cost Optimization

- Use EC2 Spot Instances for non-production
- Set up auto-shutdown for non-business hours
- Use smaller instance types if possible
- Clean up old Docker images regularly
- Use S3 for backups instead of EBS snapshots

## Next Steps

- Set up monitoring (CloudWatch, Prometheus)
- Configure alerts
- Set up CI/CD for multiple environments
- Implement blue-green deployments
- Add security scanning stages

