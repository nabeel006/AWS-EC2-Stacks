# Jenkins CI/CD Quick Start

## Quick Setup (5 minutes)

### Prerequisites Check
```bash
# Verify all tools are installed
minikube version
kubectl version --client
terraform version
docker --version
```

### Option A: Jenkins on Host (Easiest)

1. **Install Jenkins:**
   ```bash
   brew install jenkins-lts
   brew services start jenkins-lts
   ```

2. **Access Jenkins:**
   - Open: `http://localhost:8080`
   - Get password: `cat ~/.jenkins/secrets/initialAdminPassword`

3. **Create Pipeline:**
   - New Item → Pipeline
   - Name: `aks-data-structures-pipeline`
   - Pipeline → Definition: "Pipeline script from SCM"
   - SCM: Git → Repository URL: `<your-repo-url>`
   - Script Path: `Jenkinsfile`

4. **Configure GitHub Webhook:**
   - GitHub Repo → Settings → Webhooks → Add webhook
   - URL: `http://<your-ip>:8080/github-webhook/`
   - Events: Push events

5. **Run Pipeline:**
   - Click "Build Now" or push to GitHub

### Option B: Jenkins in Kubernetes

1. **Deploy Jenkins:**
   ```bash
   kubectl apply -f jenkins/jenkins-deployment-host-access.yaml
   kubectl wait --for=condition=available deployment/jenkins
   ```

2. **Access Jenkins:**
   ```bash
   MINIKUBE_IP=$(minikube ip)
   echo "Jenkins: http://${MINIKUBE_IP}:32081"
   ```

3. **Get Password:**
   ```bash
   kubectl exec deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
   ```

4. **Follow steps 3-5 from Option A**

## Pipeline Flow

```
Git Push → GitHub Webhook → Jenkins Pipeline
   ↓
1. Checkout Code
2. Ensure Minikube Running
3. Point Docker to Minikube
4. Build All Images
5. Terraform Apply
6. Verify Pods
7. (Optional) Port-Forward
```

## Troubleshooting

**Pipeline fails at Minikube step?**
- Ensure Minikube is installed: `which minikube`
- Start manually: `minikube start`

**Docker build fails?**
- Check Docker: `docker ps`
- Point to Minikube: `eval $(minikube docker-env)`

**Terraform fails?**
- Check kubectl: `kubectl get nodes`
- Verify context: `kubectl config current-context`

**Pods not ready?**
- Check status: `kubectl get pods`
- View logs: `kubectl logs <pod-name>`

## Access URLs After Deployment

```bash
MINIKUBE_IP=$(minikube ip)
echo "Web UI: http://${MINIKUBE_IP}:32080/"
echo "API: http://${MINIKUBE_IP}:32080/api/dashboard"
```

## Next Steps

- Add test stages
- Configure notifications
- Set up multiple environments
- Add security scanning

