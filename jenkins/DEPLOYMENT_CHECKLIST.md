# EC2 Jenkins Deployment Checklist

Use this checklist to ensure you complete all steps for deploying your application via Jenkins on EC2.

## ☑️ Pre-Deployment Checklist

### AWS Setup
- [ ] AWS account created and accessible
- [ ] EC2 instance launched (t3.medium or larger, Ubuntu 22.04)
- [ ] Security group configured with required ports (22, 8080, 32080)
- [ ] SSH key pair created and downloaded (.pem file)
- [ ] Can SSH into EC2 instance successfully

### GitHub Setup
- [ ] Repository pushed to GitHub
- [ ] GitHub Personal Access Token (PAT) created with `repo` and `workflow` scopes
- [ ] PAT token saved securely (you'll need it for Jenkins)

### Local Files Updated
- [ ] `Jenkinsfile-EC2` exists in repository root
- [ ] `REPO_URL` in `Jenkinsfile-EC2` updated with your GitHub username
- [ ] Changes committed and pushed to GitHub

## ☑️ EC2 Installation Checklist

### Connect to EC2
- [ ] SSH key permissions set: `chmod 400 your-key.pem`
- [ ] Successfully connected: `ssh -i your-key.pem ubuntu@<EC2-IP>`

### Run Setup Script
- [ ] Setup script downloaded or created on EC2
- [ ] Script made executable: `chmod +x setup-ec2-jenkins.sh`
- [ ] Script executed: `./setup-ec2-jenkins.sh`
- [ ] All components installed successfully

### Post-Installation
- [ ] Logged out and back in for Docker group changes
- [ ] Docker works without sudo: `docker ps`
- [ ] Minikube started: `minikube start --driver=docker --memory=4096 --cpus=2`
- [ ] Minikube running: `minikube status`
- [ ] kubectl works: `kubectl get nodes`

### Verify Installations
```bash
# Run these commands on EC2 to verify:
- [ ] java -version          # Should show Java 17
- [ ] docker --version       # Should show Docker version
- [ ] minikube version       # Should show Minikube version
- [ ] kubectl version        # Should show kubectl version
- [ ] terraform version      # Should show Terraform version
- [ ] git --version          # Should show Git version
```

## ☑️ Jenkins Configuration Checklist

### Initial Setup
- [ ] Jenkins accessible at `http://<EC2-IP>:8080`
- [ ] Initial admin password retrieved: `cat ~/.jenkins/secrets/initialAdminPassword`
- [ ] Initial admin password entered in Jenkins UI
- [ ] Suggested plugins installed
- [ ] Admin user created with strong password

### Plugin Installation
- [ ] SSH Agent Plugin installed
- [ ] GitHub Plugin installed
- [ ] Pipeline Plugin installed (should be pre-installed)
- [ ] Git Plugin installed (should be pre-installed)
- [ ] Credentials Binding Plugin installed (should be pre-installed)

### Credentials Configuration
Go to: **Manage Jenkins** → **Manage Credentials** → **(global)** → **Add Credentials**

#### Credential 1: GitHub PAT Token
- [ ] Kind: Secret text
- [ ] Scope: Global
- [ ] Secret: (your GitHub PAT)
- [ ] ID: `github-pat-token`
- [ ] Description: GitHub PAT for repository access
- [ ] Created successfully

#### Credential 2: EC2 SSH Key
- [ ] Kind: SSH Username with private key
- [ ] Scope: Global
- [ ] ID: `ec2-ssh-key`
- [ ] Description: EC2 SSH Key
- [ ] Username: `ubuntu`
- [ ] Private Key: Enter directly (paste .pem file content)
- [ ] Created successfully

#### Credential 3: EC2 Host IP
- [ ] Kind: Secret text
- [ ] Scope: Global
- [ ] Secret: (your EC2 public IP)
- [ ] ID: `ec2-host-ip`
- [ ] Description: EC2 Host IP Address
- [ ] Created successfully

## ☑️ Pipeline Creation Checklist

### Create Pipeline Job
- [ ] Clicked **New Item**
- [ ] Name: `aks-data-structures-deployment`
- [ ] Type: Pipeline
- [ ] Job created

### Configure Pipeline
#### General Section
- [ ] **GitHub project** checked
- [ ] Project URL: `https://github.com/YOUR-USERNAME/aks_data_structures/`

#### Build Triggers
- [ ] **GitHub hook trigger for GITScm polling** checked

#### Pipeline Section
- [ ] Definition: Pipeline script from SCM
- [ ] SCM: Git
- [ ] Repository URL: `https://github.com/YOUR-USERNAME/aks_data_structures.git`
- [ ] Credentials: `github-pat-token` selected
- [ ] Branch Specifier: `*/main` (or your branch)
- [ ] Script Path: `Jenkinsfile-EC2`
- [ ] Configuration saved

## ☑️ First Build Checklist

### Manual Build
- [ ] Clicked **Build with Parameters**
- [ ] Parameters reviewed (defaults are fine for first build)
- [ ] Build started
- [ ] Build number visible (e.g., #1)

### Monitor Build
- [ ] Clicked on build number
- [ ] **Console Output** opened
- [ ] Watching build progress

### Build Stages
- [ ] Stage 1: Checkout & Clone to EC2 - SUCCESS
- [ ] Stage 2: Ensure Minikube is Running - SUCCESS
- [ ] Stage 3: Build Docker Images - SUCCESS
- [ ] Stage 4: Deploy with Terraform - SUCCESS
- [ ] Stage 5: Verify Deployment - SUCCESS
- [ ] Overall build: SUCCESS ✓

## ☑️ Verification Checklist

### On EC2 (SSH)
```bash
# Run these commands to verify:
- [ ] kubectl get pods                    # All pods Running
- [ ] kubectl get services                # All services listed
- [ ] kubectl get deployments             # All deployments ready
- [ ] minikube ip                         # Get Minikube IP
```

### From Browser
- [ ] UI accessible: `http://<EC2-IP>:32080/`
- [ ] UI loads correctly
- [ ] "Fetch Data" button works
- [ ] Data displays from all services
- [ ] Backend API accessible: `http://<EC2-IP>:32080/api/dashboard`
- [ ] Backend returns JSON data

### Test All Services
- [ ] Stack service responding
- [ ] LinkedList service responding
- [ ] Graph service responding
- [ ] Backend aggregator working
- [ ] UI displaying all data

## ☑️ GitHub Webhook Setup (Optional)

### Configure Webhook
- [ ] GitHub repository → Settings → Webhooks
- [ ] **Add webhook** clicked
- [ ] Payload URL: `http://<EC2-IP>:8080/github-webhook/`
- [ ] Content type: `application/json`
- [ ] Events: Just the push event
- [ ] Active: checked
- [ ] Webhook created

### Test Webhook
- [ ] Made small change to repository
- [ ] Committed and pushed
- [ ] Jenkins automatically triggered build
- [ ] Build completed successfully

## ☑️ Post-Deployment Checklist

### Documentation
- [ ] EC2 public IP documented
- [ ] Jenkins admin password saved securely
- [ ] GitHub PAT token saved securely
- [ ] SSH key backed up

### Access URLs Documented
- [ ] Jenkins UI: `http://<EC2-IP>:8080`
- [ ] Application UI: `http://<EC2-IP>:32080/`
- [ ] Backend API: `http://<EC2-IP>:32080/api/dashboard`

### Security
- [ ] Jenkins admin password changed from default
- [ ] EC2 security group reviewed
- [ ] SSH key permissions correct (400)
- [ ] GitHub PAT has minimal required permissions

### Monitoring
- [ ] Know how to check Jenkins logs: `sudo journalctl -u jenkins -f`
- [ ] Know how to check pod logs: `kubectl logs -f deployment/backend-deployment`
- [ ] Know how to restart services if needed

## ☑️ Troubleshooting Knowledge

### Know How To:
- [ ] Restart Jenkins: `sudo systemctl restart jenkins`
- [ ] Restart Minikube: `minikube stop && minikube start`
- [ ] View Jenkins logs: `sudo journalctl -u jenkins -f`
- [ ] View pod logs: `kubectl logs <pod-name>`
- [ ] Rebuild images if needed
- [ ] Access EC2 via SSH
- [ ] Check security group settings

## 📊 Final Status

### Deployment Status
- [ ] ✅ EC2 instance running
- [ ] ✅ All prerequisites installed
- [ ] ✅ Jenkins running and accessible
- [ ] ✅ Minikube cluster running
- [ ] ✅ Pipeline configured correctly
- [ ] ✅ First build successful
- [ ] ✅ Application accessible
- [ ] ✅ All services working
- [ ] ✅ GitHub webhook configured (optional)

### Next Steps
- [ ] Set up monitoring (CloudWatch, Prometheus)
- [ ] Configure SSL/TLS with Let's Encrypt
- [ ] Set up domain name with Route 53
- [ ] Configure automated backups
- [ ] Add testing stages to pipeline
- [ ] Set up multiple environments

## 🎉 Completion

If all items are checked, congratulations! Your Jenkins CI/CD pipeline is successfully deployed on EC2!

**Application URL**: `http://<EC2-IP>:32080/`

---

## 📝 Notes Section

Use this space to document any issues encountered and their solutions:

```
Issue:
Solution:

Issue:
Solution:
```

---

**Date Completed**: _______________
**Completed By**: _______________
**EC2 Instance ID**: _______________
**EC2 Public IP**: _______________
