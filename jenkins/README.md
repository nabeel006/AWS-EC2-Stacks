# Jenkins CI/CD Pipeline

This directory contains Jenkins configuration and setup files for automating the deployment of the AKS Data Structures microservices application.

## Files Overview

### `Jenkinsfile`
The main Jenkins pipeline definition located in the project root. This pipeline:
- Checks out code from GitHub
- Ensures Minikube is running
- Points Docker to Minikube
- Builds all service images
- Deploys using Terraform
- Verifies pods and services
- Optionally sets up port-forwarding

### `jenkins-deployment.yaml`
Basic Jenkins deployment for Kubernetes (standard Jenkins image).

### `jenkins-deployment-host-access.yaml`
Advanced Jenkins deployment with host access for Minikube operations. This allows Jenkins running inside Kubernetes to:
- Access host Docker socket
- Run Minikube commands
- Access host tools (terraform, kubectl, minikube)

### `Dockerfile`
Custom Jenkins image with pre-installed tools (kubectl, terraform, minikube, docker). Useful for creating a Jenkins image with all required dependencies.

### `START_HERE.md`
**Start here!** Quick overview and getting started guide.

### `LOCAL_SETUP.md`
**For local development** - Detailed guide for setting up Jenkins on your Mac.

### `EC2_SETUP.md`
**For EC2 deployment** - Complete guide for deploying Jenkins on AWS EC2.

### `JENKINS_SETUP.md`
Comprehensive setup guide with detailed instructions for both deployment options.

### `QUICK_START.md`
Quick reference guide for fast setup.

### `setup-local-jenkins.sh`
Automated setup script for local Jenkins installation (macOS).

## Pipeline Stages

The Jenkins pipeline (`Jenkinsfile`) consists of the following stages:

1. **Checkout Code**: Checks out code from GitHub repository
2. **Ensure Minikube is Running**: Starts Minikube if not already running
3. **Point Docker to Minikube**: Configures Docker to use Minikube's Docker daemon
4. **Build All Service Images**: Builds Docker images for all services:
   - stack-service
   - linkedlist-service
   - graph-service
   - backend-service
   - ui-service
5. **Terraform Init + Apply**: Initializes and applies Terraform configuration
6. **Verify Pods & Services**: Waits for pods to be ready and verifies deployment
7. **Optional Port-Forward**: Sets up port-forwarding if enabled via parameter

## Usage

### Setting Up Jenkins

**For Local Development (macOS):**
- 🚀 **Quick Start**: Run `./setup-local-jenkins.sh` (automated)
- 📖 **Detailed Guide**: See `LOCAL_SETUP.md`
- ⚡ **Quick Reference**: See `QUICK_START.md`

**For EC2 Deployment:**
- 📖 **Complete Guide**: See `EC2_SETUP.md`
- Follow step-by-step instructions for AWS EC2

**For Kubernetes Deployment:**
- Use `jenkins-deployment-host-access.yaml` for host access
- Requires proper volume mounts and permissions
- See `JENKINS_SETUP.md` for details

### Configuring the Pipeline

1. Create a new Pipeline job in Jenkins
2. Configure it to use "Pipeline script from SCM"
3. Point to your GitHub repository
4. Set Script Path to `Jenkinsfile`

### GitHub Webhook Setup

1. Go to your GitHub repository → Settings → Webhooks
2. Add webhook with URL: `http://<jenkins-host>:<port>/github-webhook/`
3. Select "Just the push event"
4. Save

### Pipeline Parameters

The pipeline supports the following parameters:
- `ENABLE_PORT_FORWARD`: Enable port-forwarding after deployment (default: false)
- `MINIKUBE_PROFILE`: Minikube profile name (default: minikube)
- `TERRAFORM_WORKSPACE`: Terraform workspace to use (default: local)

## CI/CD Flow

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

## Troubleshooting

See `JENKINS_SETUP.md` for detailed troubleshooting guide.

Common issues:
- **Minikube not accessible**: Ensure Minikube is installed and accessible
- **Docker build fails**: Verify Docker is pointing to Minikube
- **Terraform fails**: Check kubectl context and Terraform installation
- **Pods not ready**: Check pod logs and events

## Security Considerations

- Use Jenkins credentials store for sensitive data
- Restrict webhook access appropriately
- Be cautious when mounting Docker socket (security risk)
- Use proper authentication and authorization in production

## Next Steps

- Add automated testing stages
- Configure notifications (email, Slack)
- Set up deployment to multiple environments
- Add security scanning (vulnerability scanning, SAST)
- Implement blue-green or canary deployments

