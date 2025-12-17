# How to Verify Jenkins Pipeline is Running Correctly

## ✅ Your Pipeline is Working!

Based on your successful build #3, your Jenkins pipeline is working correctly! Here's how to verify and monitor it.

## Step 1: View Pipeline Console Output

To see exactly what the pipeline did:

1. **In Jenkins UI:**
   - Go to your build (#3)
   - Click **"Console Output"** (left sidebar)
   - This shows all stages and their execution

2. **What you should see:**
   ```
   Stage 1: Checking out code from GitHub ✓
   Stage 2: Ensuring Minikube is running ✓
   Stage 3: Pointing Docker to Minikube ✓
   Stage 4: Building all service images ✓
   Stage 5: Running Terraform init + apply ✓
   Stage 6: Verifying pods and services ✓
   ```

## Step 2: Verify Deployment Status

### Check Pods (All Services Running)

```bash
kubectl get pods
```

**Expected Output:**
- ✅ All pods should show `STATUS: Running`
- ✅ All pods should show `READY: 1/1` or `2/2`
- ✅ Services: backend, graph, linkedlist, stack, ui

### Check Services

```bash
kubectl get services
```

**Expected Output:**
- ✅ backend-service (port 5000)
- ✅ graph-service (port 5003)
- ✅ linkedlist-service (port 5002)
- ✅ stack-service (port 5001)
- ✅ ui-service (port 80)

### Check Deployments

```bash
kubectl get deployments
```

**Expected Output:**
- ✅ All deployments show `READY: 2/2` (or configured replicas)
- ✅ All deployments show `AVAILABLE: 2`

## Step 3: Access Your Application

### Get Minikube IP

```bash
minikube ip
```

### Access URLs

```bash
# Web UI
http://<minikube-ip>:32080/

# Backend API
http://<minikube-ip>:32080/api/dashboard
```

### Quick Access Command

```bash
MINIKUBE_IP=$(minikube ip)
echo "Web UI: http://${MINIKUBE_IP}:32080/"
echo "API: http://${MINIKUBE_IP}:32080/api/dashboard"
```

## Step 4: Monitor Pipeline Execution

### In Jenkins UI

1. **Build History:**
   - See all builds (successful ✅, failed ❌, in progress 🔵)
   - Click any build to see details

2. **Console Output:**
   - Real-time logs of what's happening
   - Shows each stage execution
   - Shows errors if any

3. **Stage View:**
   - Visual representation of pipeline stages
   - Shows which stage is running
   - Shows duration of each stage

### From Command Line

```bash
# Watch pods being created (during pipeline run)
watch kubectl get pods

# View pod logs
kubectl logs -f deployment/backend-deployment

# Check service endpoints
kubectl get endpoints
```

## Step 5: Understanding Pipeline Stages

Your Jenkinsfile runs these stages in order:

### Stage 1: Checkout Code ✅
- Pulls code from GitHub
- Shows branch and commit info

### Stage 2: Ensure Minikube is Running ✅
- Checks if Minikube is running
- Starts it if needed

### Stage 3: Point Docker to Minikube ✅
- Configures Docker to use Minikube's Docker daemon
- Required for building images that Minikube can use

### Stage 4: Build All Service Images ✅
- Builds Docker images for:
  - stack-service
  - linkedlist-service
  - graph-service
  - backend-service
  - ui-service

### Stage 5: Terraform Init + Apply ✅
- Initializes Terraform
- Applies Kubernetes manifests
- Deploys all services to Minikube

### Stage 6: Verify Pods & Services ✅
- Waits for pods to be ready
- Verifies all services are running
- Shows deployment status

### Stage 7: Optional Port-Forward
- Only runs if enabled via parameter
- Sets up port-forwarding for local access

## Step 6: Test Your Application

### Test Web UI

```bash
MINIKUBE_IP=$(minikube ip)
curl http://${MINIKUBE_IP}:32080/
```

### Test Backend API

```bash
MINIKUBE_IP=$(minikube ip)
curl http://${MINIKUBE_IP}:32080/api/dashboard
```

### Test Individual Services

```bash
# Stack service
kubectl port-forward svc/stack-service 5001:5001 &
curl http://localhost:5001/

# Graph service
kubectl port-forward svc/graph-service 5003:5003 &
curl http://localhost:5003/graph

# Backend service
kubectl port-forward svc/backend-service 5000:5000 &
curl http://localhost:5000/health
```

## Step 7: Monitor Future Builds

### Automatic Triggers (Webhook)

When you push to GitHub:
1. GitHub sends webhook to Jenkins
2. Jenkins automatically starts new build
3. Pipeline runs all stages
4. Services are redeployed

### Manual Triggers

1. Go to Jenkins → Your Pipeline
2. Click **"Build Now"**
3. Watch the build execute

## Troubleshooting

### If Build Fails

1. **Check Console Output:**
   - Go to failed build
   - Click "Console Output"
   - Look for error messages

2. **Common Issues:**

   **Minikube not running:**
   ```bash
   minikube start
   ```

   **Docker build fails:**
   ```bash
   eval $(minikube docker-env)
   docker ps
   ```

   **Pods not ready:**
   ```bash
   kubectl get pods
   kubectl describe pod <pod-name>
   kubectl logs <pod-name>
   ```

### If Services Not Accessible

1. **Check Ingress:**
   ```bash
   kubectl get ingress
   kubectl describe ingress
   ```

2. **Check NodePort:**
   ```bash
   kubectl get services -o wide
   ```

3. **Check Minikube IP:**
   ```bash
   minikube ip
   ```

## Quick Verification Checklist

- [ ] Build completed successfully (green checkmark)
- [ ] All pods are Running
- [ ] All services are created
- [ ] All deployments are ready
- [ ] Application is accessible via Minikube IP
- [ ] Webhook is triggering builds automatically

## Next Steps

1. ✅ **Monitor builds** - Watch console output for each build
2. ✅ **Test application** - Access via Minikube IP
3. ✅ **Make changes** - Push to GitHub and watch auto-deploy
4. 📋 **Deploy to EC2** - When ready for production (see EC2_SETUP.md)

---

**Your pipeline is working! 🎉**

Every time you push to GitHub, Jenkins will:
1. Pull your latest code
2. Build all Docker images
3. Deploy to Minikube
4. Verify everything is running

You can now focus on developing, and Jenkins handles the deployment automatically!




