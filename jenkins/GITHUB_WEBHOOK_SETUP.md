# GitHub Webhook Setup Guide

This guide will help you set up GitHub webhooks to automatically trigger Jenkins pipelines when you push code.

## Prerequisites

- ✅ Jenkins is running and accessible
- ✅ GitHub repository is connected to Jenkins pipeline
- ✅ Pipeline job is created in Jenkins

## Step 1: Get Your Jenkins Webhook URL

### For Local Development

If Jenkins is running locally on your Mac:

1. **Get your local IP address:**
   ```bash
   # macOS
   ipconfig getifaddr en0
   # or
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```

2. **Your webhook URL will be:**
   ```
   http://<your-local-ip>:8080/github-webhook/
   ```
   Example: `http://192.168.1.100:8080/github-webhook/`

### Important Notes for Local Setup

⚠️ **GitHub cannot reach your local IP directly** if you're behind a router/firewall. You have two options:

**Option A: Use ngrok (Recommended for Testing)**
- Creates a public URL that tunnels to your local Jenkins
- Free and easy to set up
- See instructions below

**Option B: Manual Trigger**
- Use "Build Now" button in Jenkins
- Works without webhook setup
- Good for initial testing

## Step 2: Set Up GitHub Webhook

### Method 1: Using ngrok (For Local Testing)

1. **Install ngrok:**
   ```bash
   brew install ngrok
   # Or download from: https://ngrok.com/download
   ```

2. **Start ngrok tunnel:**
   ```bash
   ngrok http 8080
   ```

3. **Copy the forwarding URL:**
   - You'll see something like: `https://abc123.ngrok.io`
   - Copy this URL

4. **Configure GitHub Webhook:**
   - Go to your GitHub repository
   - Click **Settings** → **Webhooks** → **Add webhook**
   - **Payload URL**: `https://abc123.ngrok.io/github-webhook/`
   - **Content type**: `application/json`
   - **Events**: Select **Just the push event**
   - **Active**: ✓
   - Click **Add webhook**

5. **Keep ngrok running:**
   - Keep the ngrok terminal window open
   - The URL changes each time you restart ngrok (unless you have a paid account)

### Method 2: Direct IP (If Accessible from Internet)

1. **Get your public IP:**
   ```bash
   curl ifconfig.me
   ```

2. **Configure router port forwarding:**
   - Forward port 8080 to your Mac's local IP
   - This requires router admin access

3. **Configure GitHub Webhook:**
   - **Payload URL**: `http://<your-public-ip>:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Events**: Just the push event
   - **Active**: ✓

### Method 3: For EC2/Cloud Deployment

When you deploy to EC2 (see `EC2_SETUP.md`):

1. **Get EC2 public IP:**
   ```bash
   curl http://169.254.169.254/latest/meta-data/public-ipv4
   ```

2. **Configure GitHub Webhook:**
   - **Payload URL**: `http://<ec2-public-ip>:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Events**: Just the push event
   - **Active**: ✓

3. **Ensure Security Group allows port 8080**

## Step 3: Configure Jenkins for Webhooks

1. **Go to Jenkins:**
   - Open http://localhost:8080

2. **Manage Jenkins → Configure System:**
   - Scroll to **GitHub** section
   - Click **Advanced** under GitHub
   - Ensure **Specify another hook URL** is NOT checked (for default `/github-webhook/`)

3. **Verify GitHub Plugin is installed:**
   - Manage Jenkins → Manage Plugins → Installed
   - Look for "GitHub plugin"
   - If missing, install it from Available plugins

## Step 4: Test the Webhook

### Test 1: Manual Trigger (Verify Pipeline Works)

1. **Go to your pipeline in Jenkins:**
   - Click on your pipeline job
   - Click **Build Now**

2. **Watch the build:**
   - Click on the build number
   - Click **Console Output**
   - Verify all stages complete successfully

### Test 2: Webhook Trigger

1. **Make a small change to your repo:**
   ```bash
   # Add a comment or small change
   echo "# Test" >> README.md
   git add README.md
   git commit -m "Test webhook"
   git push
   ```

2. **Check Jenkins:**
   - Go to Jenkins dashboard
   - You should see a new build automatically triggered
   - The build should appear within seconds of pushing

3. **Verify webhook delivery:**
   - Go to GitHub → Your Repo → Settings → Webhooks
   - Click on your webhook
   - You should see recent deliveries
   - Green checkmark = successful
   - Red X = failed (check the response)

## Step 5: Troubleshooting

### Issue: Webhook not triggering builds

**Check 1: Webhook URL**
- Verify URL is correct: `http://<ip>:8080/github-webhook/`
- Note the trailing slash `/` is important
- For ngrok: Use HTTPS URL

**Check 2: Jenkins GitHub Plugin**
- Ensure GitHub plugin is installed
- Restart Jenkins if you just installed it

**Check 3: GitHub Webhook Delivery**
- Go to GitHub → Repo → Settings → Webhooks
- Click on your webhook
- Check "Recent Deliveries"
- Click on a delivery to see response
- Should return 200 OK

**Check 4: Jenkins Logs**
```bash
tail -f ~/.jenkins/logs/jenkins.log
```
Look for webhook-related errors

**Check 5: Firewall/Security**
- Ensure port 8080 is accessible
- Check macOS firewall settings
- For ngrok: Ensure ngrok is running

### Issue: "No suitable agents" error

**Solution:**
- This means Jenkins doesn't have an executor available
- Go to: Manage Jenkins → Configure System
- Increase **# of executors** (default is usually 2)

### Issue: ngrok URL changes

**Solution:**
- Free ngrok URLs change on restart
- For stable URL, use ngrok authtoken and reserved domain (paid)
- Or use a service like localtunnel.me

## Alternative: Using GitHub Actions (Advanced)

Instead of webhooks, you can use GitHub Actions to trigger Jenkins:

1. Create `.github/workflows/jenkins.yml`
2. Use GitHub Actions to call Jenkins API
3. More control but requires additional setup

## Quick Reference

### Local Testing (ngrok)
```bash
# Terminal 1: Start ngrok
ngrok http 8080

# Terminal 2: Keep Jenkins running
# Use the ngrok URL in GitHub webhook
```

### Manual Trigger (No Webhook Needed)
- Just click "Build Now" in Jenkins
- Works immediately
- Good for testing

### Webhook URL Format
```
http://<host>:8080/github-webhook/
https://<ngrok-url>/github-webhook/  (for ngrok)
```

## Next Steps

Once webhook is working:

1. ✅ Push code → Automatic build
2. ✅ Monitor builds in Jenkins
3. ✅ Check deployment in Minikube
4. ✅ Access application at http://<minikube-ip>:32080

---

**Need help?** Check Jenkins logs: `tail -f ~/.jenkins/logs/jenkins.log`




