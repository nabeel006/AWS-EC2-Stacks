# Setup Script Features

The `setup-local-jenkins.sh` script is designed to be **fully automated** and work on any macOS machine. Here's what it does:

## ✅ Automatic Prerequisites Installation

The script automatically installs all required tools if they're missing:

1. **Homebrew** - Package manager (installs if missing)
2. **Git** - Version control (installs via Homebrew)
3. **Minikube** - Local Kubernetes (installs via Homebrew)
4. **kubectl** - Kubernetes CLI (installs via Homebrew)
5. **Terraform** - Infrastructure as Code (installs via Homebrew)
6. **Docker** - Container platform (checks if installed, guides if missing)
7. **Jenkins LTS** - CI/CD server (installs via Homebrew)

## 🚀 What the Script Does

### Step 1: Prerequisites Check & Installation
- Checks for Homebrew, installs if missing
- Checks for each tool, installs if missing
- Verifies Docker is installed and running

### Step 2: Jenkins Installation
- Checks if Jenkins is already installed
- Installs Jenkins LTS if needed
- No user prompts required

### Step 3: Jenkins Startup
- Starts Jenkins service automatically
- Waits for Jenkins to be ready (up to 60 seconds)
- Verifies Jenkins is accessible

### Step 4: Minikube Setup
- Checks if Minikube is running
- Starts Minikube automatically if not running
- Displays Minikube IP

### Step 5: Summary
- Shows Jenkins access URL
- Displays admin password
- Lists all installed prerequisites
- Provides next steps

## 📋 Requirements

The script only requires:
- **macOS** (any recent version)
- **Internet connection** (for downloading tools)
- **Administrator password** (for Homebrew installation, if needed)
- **Docker Desktop** (must be installed and running - cannot be automated)

## ⚠️ Manual Steps Required

Only **one thing** requires manual action:

### Docker Desktop
- Docker Desktop cannot be installed via command line
- You must download and install it manually: https://www.docker.com/products/docker-desktop
- Docker Desktop must be **running** before the script can proceed

## 🎯 Usage

Simply run:

```bash
cd jenkins
./setup-local-jenkins.sh
```

The script will:
- ✅ Install all missing prerequisites automatically
- ✅ Set up Jenkins
- ✅ Start Jenkins
- ✅ Configure Minikube
- ✅ Show you everything you need to get started

## 🔧 What Happens After

After the script completes:

1. **Access Jenkins**: `http://localhost:8080`
2. **Use admin password**: Shown at the end of script output
3. **Follow next steps**: Listed in the script output

## 🛠️ Troubleshooting

### If Homebrew installation fails:
- You may need to run: `xcode-select --install` first
- Or install Xcode Command Line Tools manually

### If Docker is not running:
- Start Docker Desktop manually
- Wait for it to fully start (whale icon in menu bar)
- Run the script again

### If Minikube fails to start:
- Ensure Docker Desktop is running
- Check Docker has enough resources (Settings → Resources)
- Try: `minikube delete && minikube start`

## 📝 Notes

- The script is **idempotent** - safe to run multiple times
- Already installed tools are detected and skipped
- The script provides clear feedback at each step
- All installations use Homebrew for consistency

## 🎓 Perfect For

- Setting up new development machines
- Onboarding new team members
- Quick local CI/CD setup
- Testing Jenkins pipelines locally

---

**Ready to use?** Just run `./setup-local-jenkins.sh` and everything will be set up automatically! 🚀

