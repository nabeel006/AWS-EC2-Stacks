# How to Run Jenkins Pipeline & Set Up GitHub Webhook

## Part 1: Running the Pipeline (Manual Trigger)

### Step 1: Verify Pipeline is Configured

1. **Open Jenkins:**
   ```
   http://localhost:8080
   ```

2. **Go to your pipeline:**
   - Click on your pipeline job name (e.g., `aks-data-structures-pipeline`)

3. **Verify configuration:**
   - Check that it's configured to use "Pipeline script from SCM"
   - Repository URL should point to your GitHub repo
   - Script Path should be: `Jenkinsfile`

### Step 2: Run the Pipeline Manually

1. **Click "Build Now"** (left sidebar)
   - This will trigger the pipeline immediately

2. **Watch the build:**
   - You'll see a new build appear in "Build History"
   - Click on the build number (#1, #2, etc.)
   - Click **Console Output** to see real-time logs

3. **Monitor the stages:**
   The pipeline will run through these stages:
   - ✅ Checkout Code
   - ✅ Ensure Minikube is Running
   - ✅ Point Docker to Minikube
   - ✅ Build All Service Images
   - ✅ Terraform Init + Apply
   - ✅ Verify Pods & Services
   - (Optional) Port-Forward

4. **Check results:**
   - Green ball = Success ✅
   - Red ball = Failed ❌
   - Blue ball = In Progress 🔵

### Step 3: Verify Deployment

After the pipeline completes successfully:

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

---

## Part 2: Setting Up GitHub Webhook (Automatic Trigger)

### Option A: Using ngrok (Recommended for Local Testing)

This is the easiest way to test webhooks locally.

#### Step 1: Install ngrok

```bash
brew install ngrok
```

Or download from: https://ngrok.com/download

#### Step 2: Start ngrok Tunnel

```bash
ngrok http 8080
```

You'll see output like:
```
Forwarding  https://abc123.ngrok.io -> http://localhost:8080
```

**Copy the HTTPS URL** (e.g., `https://abc123.ngrok.io`)

#### Step 3: Configure GitHub Webhook

1. **Go to your GitHub repository**
2. **Click Settings** → **Webhooks** → **Add webhook**
3. **Fill in the form:**
   - **Payload URL**: `https://abc123.ngrok.io/github-webhook/`
     - ⚠️ Use the HTTPS URL from ngrok
     - ⚠️ Include the trailing slash `/`
   - **Content type**: `application/json`
   - **Secret**: (leave empty for now, or set one for security)
   - **Events**: Select **Just the push event**
   - **Active**: ✓ (checked)
4. **Click "Add webhook"**

#### Step 4: Keep ngrok Running

- **Keep the ngrok terminal window open**
- If you close it, the URL will change
- For testing, this is fine
- For production, use a stable URL or deploy to EC2

#### Step 5: Test the Webhook

1. **Make a small change:**
   ```bash
   echo "# Test webhook" >> README.md
   git add README.md
   git commit -m "Test webhook trigger"
   git push
   ```

2. **Check Jenkins:**
   - Go to Jenkins dashboard
   - You should see a new build automatically start
   - This happens within seconds of pushing

3. **Verify in GitHub:**
   - Go to: Repo → Settings → Webhooks
   - Click on your webhook
   - Check "Recent Deliveries"
   - Should show green checkmarks ✅

---

### Option B: Manual Trigger Only (No Webhook)

If you don't want to set up webhooks right now:

1. **Just use "Build Now" button** in Jenkins
2. **Works immediately** - no webhook needed
3. **Good for initial testing** and development

---

## Part 3: Verify Everything Works

### Test 1: Manual Build

```bash
# In Jenkins UI
1. Click "Build Now"
2. Watch console output
3. Verify all stages complete
4. Check deployment: kubectl get pods
```

### Test 2: Webhook Trigger

```bash
# Make a change and push
echo "test" >> test.txt
git add test.txt
git commit -m "Test webhook"
git push

# Check Jenkins - should auto-trigger build
```

---

## Troubleshooting

### Pipeline Fails at Minikube Stage

**Solution:**
```bash
# Ensure Minikube is running
minikube status
minikube start  # if not running
```

### Pipeline Fails at Docker Build

**Solution:**
```bash
# Point Docker to Minikube
eval $(minikube docker-env)
docker ps  # should work
```

### Webhook Not Triggering

**Check 1: ngrok is running**
```bash
# Keep ngrok terminal open
ngrok http 8080
```

**Check 2: Webhook URL is correct**
- Must be: `https://<ngrok-url>/github-webhook/`
- Include trailing slash
- Use HTTPS (not HTTP) for ngrok

**Check 3: GitHub Webhook Delivery**
- Go to: Repo → Settings → Webhooks
- Click webhook → Recent Deliveries
- Check response - should be 200 OK

**Check 4: Jenkins GitHub Plugin**
- Manage Jenkins → Manage Plugins → Installed
- Ensure "GitHub plugin" is installed
- Restart Jenkins if needed

### Build Shows "No suitable agents"

**Solution:**
- Manage Jenkins → Configure System
- Increase **# of executors** (default is 2)

---

## Quick Commands Reference

```bash
# Start Jenkins (if stopped)
brew services start jenkins-lts

# Check Jenkins status
brew services list | grep jenkins

# View Jenkins logs
tail -f ~/.jenkins/logs/jenkins.log

# Start ngrok (for webhook)
ngrok http 8080

# Check Minikube
minikube status
minikube ip

# Check deployment
kubectl get pods
kubectl get services
```

---

## Next Steps

Once everything is working:

1. ✅ Pipeline runs successfully
2. ✅ Webhook triggers on git push
3. ✅ Services deploy to Minikube
4. ✅ Access application at http://<minikube-ip>:32080

**Ready to deploy to EC2?** See `EC2_SETUP.md` for cloud deployment guide.




