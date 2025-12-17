# Testing Your GitHub Webhook

## Your Webhook Configuration

**Webhook URL:** `https://colory-lucius-unremuneratively.ngrok-free.dev/github-webhook/`

## Step 1: Verify ngrok is Running

Make sure ngrok is running in a terminal:

```bash
ngrok http 8080
```

You should see your URL: `https://colory-lucius-unremuneratively.ngrok-free.dev`

## Step 2: Verify Webhook in GitHub

1. Go to your GitHub repository
2. **Settings** → **Webhooks**
3. Find your webhook with URL: `https://colory-lucius-unremuneratively.ngrok-free.dev/github-webhook/`
4. Click on it to see details
5. Check "Recent Deliveries" - should show recent pushes

## Step 3: Test the Webhook (Deploy via Jenkins)

Since we deleted all deployments, let's trigger a fresh deployment:

### Option A: Push a Change to GitHub (Automatic)

1. **Make a small change:**
   ```bash
   echo "# Deploying via Jenkins" >> README.md
   git add README.md
   git commit -m "Trigger Jenkins deployment"
   git push
   ```

2. **Watch Jenkins:**
   - Go to http://localhost:8080
   - You should see a new build start automatically
   - Watch it deploy everything fresh

### Option B: Manual Trigger in Jenkins

1. **Open Jenkins:** http://localhost:8080
2. **Go to your pipeline:** `aks-data-structures-pipeline`
3. **Click "Build Now"**
4. **Watch the build:**
   - Click on the build number
   - Click "Console Output"
   - Watch it deploy all services

## Step 4: Verify Deployment

After the build completes:

```bash
# Check pods (should be newly created)
kubectl get pods

# Check services
kubectl get services

# Check deployments
kubectl get deployments

# Get access URL
minikube ip
```

## Expected Results

After Jenkins pipeline runs, you should see:

✅ **New pods created** (not the old ones)
✅ **All services deployed**
✅ **All deployments ready**
✅ **Application accessible** at http://<minikube-ip>:32080

## Troubleshooting

### Webhook Not Triggering?

1. **Check ngrok is running:**
   ```bash
   # Should see ngrok process
   ps aux | grep ngrok
   ```

2. **Check GitHub webhook delivery:**
   - Go to: Repo → Settings → Webhooks
   - Click your webhook
   - Check "Recent Deliveries"
   - Should show 200 OK responses

3. **Check Jenkins logs:**
   ```bash
   tail -f ~/.jenkins/logs/jenkins.log
   ```

### ngrok URL Changed?

If ngrok restarts, the URL changes. Update GitHub webhook:
1. Get new URL from ngrok terminal
2. Update webhook in GitHub with new URL

### Jenkins Not Receiving Webhooks?

1. **Verify GitHub plugin is installed:**
   - Manage Jenkins → Manage Plugins → Installed
   - Look for "GitHub plugin"

2. **Check Jenkins configuration:**
   - Manage Jenkins → Configure System
   - Under "GitHub", ensure webhook URL matches

## Quick Test Command

```bash
# Make a test commit and push
echo "Test $(date)" >> test.txt
git add test.txt
git commit -m "Test Jenkins deployment"
git push

# Then check Jenkins - should auto-trigger build
```

---

**Ready to test?** Make a small change and push to GitHub, or click "Build Now" in Jenkins!


