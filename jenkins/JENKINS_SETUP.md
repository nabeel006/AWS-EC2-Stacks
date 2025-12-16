# Jenkins CI/CD Setup Guide

This guide explains how to set up Jenkins for the CI/CD pipeline that automates deployment to Minikube.

## Architecture Overview

The CI/CD pipeline follows this flow:

```
Git Push
   ↓
GitHub Webhook
   ↓
Jenkins Pipeline
   ├─ Checkout code
   ├─ Ensure Minikube is running
   ├─ Point Docker to Minikube
   ├─ Build all service images
   ├─ Terraform init + apply
   ├─ Verify pods & services
   └─ (Optional) Port-forward
```

## Prerequisites

Before setting up Jenkins, ensure you have:

1. **Minikube** installed and accessible
2. **kubectl** installed
3. **Terraform** installed
4. **Docker** installed
5. **GitHub repository** with webhook access

## Option 1: Jenkins Running on Host Machine (Recommended for Local Development)

This is the simplest approach for local development.

### Steps:

1. **Install Jenkins on your host machine:**

   ```bash
   # macOS
   brew install jenkins-lts
   
   # Or download from: https://www.jenkins.io/download/
   ```

2. **Start Jenkins:**

   ```bash
   brew services start jenkins-lts
   # Or: jenkins
   ```

3. **Access Jenkins:**

   - Open browser: `http://localhost:8080`
   - Get initial admin password:
     ```bash
     cat ~/.jenkins/secrets/initialAdminPassword
     ```

4. **Install Required Plugins:**

   - Go to: Manage Jenkins → Manage Plugins → Available
   - Install:
     - GitHub plugin
     - Pipeline plugin
     - Docker Pipeline plugin
     - Terraform plugin (optional)

5. **Configure Jenkins Pipeline:**

   - Go to: New Item → Pipeline
   - Name: `aks-data-structures-pipeline`
   - Under "Pipeline Definition":
     - Select: "Pipeline script from SCM"
     - SCM: Git
     - Repository URL: Your GitHub repository URL
     - Credentials: Add if repository is private
     - Branch: `*/main` (or your default branch)
     - Script Path: `Jenkinsfile`

6. **Configure GitHub Webhook:**

   - In your GitHub repository:
     - Go to: Settings → Webhooks → Add webhook
     - Payload URL: `http://<your-host-ip>:8080/github-webhook/`
     - Content type: `application/json`
     - Events: "Just the push event"
     - Active: ✓

## Option 2: Jenkins Running in Kubernetes (Advanced)

If you want Jenkins to run inside Minikube, you need to give it access to host tools.

### Steps:

1. **Deploy Jenkins with Host Access:**

   ```bash
   kubectl apply -f jenkins/jenkins-deployment-host-access.yaml
   ```

2. **Wait for Jenkins to be ready:**

   ```bash
   kubectl wait --for=condition=available --timeout=300s deployment/jenkins
   ```

3. **Get Jenkins access URL:**

   ```bash
   MINIKUBE_IP=$(minikube ip)
   echo "Jenkins URL: http://${MINIKUBE_IP}:32081"
   ```

4. **Get initial admin password:**

   ```bash
   kubectl exec -it deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
   ```

5. **Install Required Plugins** (same as Option 1)

6. **Configure Pipeline** (same as Option 1)

7. **Configure GitHub Webhook:**

   - Payload URL: `http://<your-host-ip>:32081/github-webhook/`
   - Note: You may need to set up port-forwarding or use a service like ngrok for webhook access

### Important Notes for Option 2:

- The deployment uses `hostPath` volumes to access host tools
- Requires `privileged: true` for Docker socket access
- Minikube must be running on the host
- Tools (terraform, minikube, kubectl) must be installed on the host

## Pipeline Configuration

The `Jenkinsfile` in the project root contains the complete pipeline definition. Key stages:

1. **Checkout Code**: Checks out code from GitHub
2. **Ensure Minikube is Running**: Starts Minikube if not running
3. **Point Docker to Minikube**: Configures Docker to use Minikube's Docker daemon
4. **Build All Service Images**: Builds Docker images for all services
5. **Terraform Init + Apply**: Deploys infrastructure using Terraform
6. **Verify Pods & Services**: Waits for pods to be ready and verifies deployment
7. **Optional Port-Forward**: Sets up port-forwarding if enabled

## Testing the Pipeline

1. **Manual Trigger:**

   - Go to Jenkins dashboard
   - Click on your pipeline
   - Click "Build Now"

2. **Test with Git Push:**

   - Make a change to your repository
   - Push to GitHub
   - Webhook should trigger the pipeline automatically

3. **Monitor Pipeline:**

   - View console output in Jenkins
   - Check logs for each stage
   - Verify deployment in Minikube:
     ```bash
     kubectl get pods
     kubectl get services
     ```

## Troubleshooting

### Issue: Pipeline fails at "Ensure Minikube is Running"

**Solution:**
- Ensure Minikube is installed: `which minikube`
- Check Minikube status: `minikube status`
- If Jenkins runs in Kubernetes, ensure hostPath volumes are mounted correctly

### Issue: Docker build fails

**Solution:**
- Ensure Docker is pointing to Minikube: `eval $(minikube docker-env)`
- Check Docker daemon is accessible
- Verify Dockerfile exists for each service

### Issue: Terraform fails

**Solution:**
- Ensure Terraform is installed: `which terraform`
- Check kubectl context: `kubectl config current-context`
- Verify Terraform files exist in `terraform/local/`

### Issue: Pods not becoming ready

**Solution:**
- Check pod logs: `kubectl logs <pod-name>`
- Check pod events: `kubectl describe pod <pod-name>`
- Verify images are built: `docker images`
- Check imagePullPolicy in Kubernetes manifests

### Issue: GitHub webhook not triggering

**Solution:**
- Verify webhook URL is accessible from GitHub
- Check Jenkins logs: `kubectl logs deployment/jenkins`
- Ensure GitHub plugin is installed
- Test webhook manually: `curl -X POST http://localhost:8080/github-webhook/`

## Security Considerations

- **For Production**: Use proper authentication and authorization
- **Secrets Management**: Use Jenkins credentials store for sensitive data
- **Network Security**: Restrict webhook access appropriately
- **Docker Socket Access**: Be cautious when mounting Docker socket (security risk)

## Next Steps

After setting up Jenkins:

1. Configure additional pipeline parameters if needed
2. Set up notifications (email, Slack, etc.)
3. Add test stages to the pipeline
4. Configure deployment to different environments
5. Set up monitoring and alerting

