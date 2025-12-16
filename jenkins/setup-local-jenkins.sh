#!/bin/bash

# Local Jenkins Setup Script
# This script automatically installs all prerequisites and sets up Jenkins locally on macOS

set -e

echo "=========================================="
echo "Local Jenkins Setup Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS"
    exit 1
fi

# Check for curl (needed for Homebrew installation)
if ! command -v curl >/dev/null 2>&1; then
    print_error "curl is required but not installed"
    echo "Please install Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

# Function to install Homebrew if not present
install_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        print_info "Homebrew not found. Installing Homebrew..."
        print_info "This may require your password and take a few minutes..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            # Add to current shell session
            export PATH="/opt/homebrew/bin:$PATH"
        elif [[ -f /usr/local/bin/brew ]]; then
            # Intel Macs
            export PATH="/usr/local/bin:$PATH"
        fi
        
        print_success "Homebrew installed"
    else
        print_success "Homebrew is installed"
        # Ensure Homebrew is in PATH
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
}

# Function to check and install a tool
check_and_install_tool() {
    local tool=$1
    local brew_package=${2:-$tool}
    
    if command -v "$tool" >/dev/null 2>&1; then
        local version_output
        version_output=$($tool --version 2>&1 | head -n 1 || echo "installed")
        print_success "$tool is installed ($version_output)"
        return 0
    else
        print_info "$tool is not installed. Installing via Homebrew..."
        brew install "$brew_package" || {
            print_error "Failed to install $tool"
            return 1
        }
        print_success "$tool installed successfully"
        return 0
    fi
}

# Check and install prerequisites
echo "Step 1: Checking and installing prerequisites..."
echo ""

# Install Homebrew first if needed
install_homebrew

# Ensure Homebrew is in PATH (already done in install_homebrew, but ensure it's set)
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export PATH="/opt/homebrew/bin:$PATH"
elif [[ -f /usr/local/bin/brew ]]; then
    export PATH="/usr/local/bin:$PATH"
fi

# Check and install tools
check_and_install_tool "git"
check_and_install_tool "minikube"
check_and_install_tool "kubectl"
check_and_install_tool "terraform"

# Special handling for Docker
echo ""
print_info "Checking Docker installation..."
if command -v docker >/dev/null 2>&1 && docker ps >/dev/null 2>&1; then
    print_success "Docker is installed and running"
elif command -v docker >/dev/null 2>&1; then
    print_info "Docker is installed but daemon is not running"
    echo ""
    echo "⚠️  Docker Desktop needs to be running for this setup."
    echo "   Please start Docker Desktop manually and run this script again."
    echo "   Or install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
else
    print_info "Docker is not installed"
    echo ""
    echo "⚠️  Docker Desktop is required but cannot be installed via command line."
    echo "   Please install Docker Desktop manually:"
    echo "   1. Download from: https://www.docker.com/products/docker-desktop"
    echo "   2. Install and start Docker Desktop"
    echo "   3. Run this script again"
    exit 1
fi

echo ""

# Check if Jenkins is already installed
echo "Step 2: Checking Jenkins installation..."
echo ""

if brew list jenkins-lts >/dev/null 2>&1; then
    print_info "Jenkins LTS is already installed via Homebrew"
    JENKINS_INSTALLED=true
elif docker ps -a --format '{{.Names}}' | grep -q "^jenkins$"; then
    print_info "Jenkins container exists"
    JENKINS_INSTALLED=true
elif [ -f ~/.jenkins/config.xml ]; then
    print_info "Jenkins appears to be installed (config found)"
    JENKINS_INSTALLED=true
else
    print_info "Jenkins is not installed"
    JENKINS_INSTALLED=false
fi

# Install Jenkins if needed
if [ "$JENKINS_INSTALLED" = false ]; then
    echo ""
    echo "Step 3: Installing Jenkins..."
    echo ""
    print_info "Installing Jenkins LTS via Homebrew..."
    brew install jenkins-lts
    print_success "Jenkins LTS installed"
else
    echo "Step 3: Skipping Jenkins installation (already installed)"
fi

# Start Jenkins
echo ""
echo "Step 4: Starting Jenkins..."
echo ""

if brew services list | grep -q "jenkins-lts.*started"; then
    print_info "Jenkins is already running"
else
    print_info "Starting Jenkins..."
    brew services start jenkins-lts
    sleep 5
    print_success "Jenkins started"
fi

# Wait for Jenkins to be ready
echo ""
echo "Step 5: Waiting for Jenkins to be ready..."
echo ""

MAX_WAIT=60
WAIT_COUNT=0

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if curl -s http://localhost:8080 >/dev/null 2>&1; then
        print_success "Jenkins is ready!"
        break
    fi
    print_info "Waiting for Jenkins... ($WAIT_COUNT/$MAX_WAIT seconds)"
    sleep 2
    WAIT_COUNT=$((WAIT_COUNT + 2))
done

if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
    print_error "Jenkins did not start in time"
    exit 1
fi

# Get initial admin password
echo ""
echo "Step 6: Getting initial admin password..."
echo ""

if [ -f ~/.jenkins/secrets/initialAdminPassword ]; then
    ADMIN_PASSWORD=$(cat ~/.jenkins/secrets/initialAdminPassword)
    print_success "Initial admin password retrieved"
    echo ""
    echo "=========================================="
    echo "Jenkins Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Access Jenkins at:"
    echo "  http://localhost:8080"
    echo ""
    echo "Initial admin password:"
    echo "  ${ADMIN_PASSWORD}"
    echo ""
    echo "Next steps:"
    echo "  1. Open http://localhost:8080 in your browser"
    echo "  2. Enter the admin password above"
    echo "  3. Install suggested plugins"
    echo "  4. Create admin user (or skip)"
    echo "  5. Install additional plugins:"
    echo "     - GitHub plugin"
    echo "     - Pipeline plugin"
    echo "     - Docker Pipeline plugin"
    echo "  6. Create pipeline job pointing to your GitHub repo"
    echo ""
    echo "Prerequisites installed:"
    echo "  ✓ Homebrew"
    echo "  ✓ Git"
    echo "  ✓ Minikube"
    echo "  ✓ kubectl"
    echo "  ✓ Terraform"
    echo "  ✓ Docker"
    echo "  ✓ Jenkins LTS"
    echo ""
    echo "See LOCAL_SETUP.md for detailed instructions"
    echo ""
else
    print_error "Could not find initial admin password"
    echo "Check Jenkins logs: tail -f ~/.jenkins/logs/jenkins.log"
fi

# Check Minikube status
echo ""
echo "Step 7: Checking Minikube status..."
echo ""

if minikube status >/dev/null 2>&1 | grep -q "Running"; then
    print_success "Minikube is running"
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "unknown")
    echo "  Minikube IP: ${MINIKUBE_IP}"
else
    print_info "Minikube is not running"
    print_info "Starting Minikube (this may take a few minutes)..."
    minikube start || {
        print_error "Failed to start Minikube"
        echo ""
        echo "Troubleshooting tips:"
        echo "  1. Ensure Docker Desktop is running"
        echo "  2. Check Docker resources: Docker Desktop → Settings → Resources"
        echo "  3. Try: minikube delete && minikube start"
        exit 1
    }
    print_success "Minikube started successfully"
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "unknown")
    echo "  Minikube IP: ${MINIKUBE_IP}"
fi

# Final summary
echo ""
echo "=========================================="
echo "Setup Summary"
echo "=========================================="
echo ""
echo "✅ All prerequisites installed and configured:"
echo "   • Homebrew"
echo "   • Git"
echo "   • Minikube"
echo "   • kubectl"
echo "   • Terraform"
echo "   • Docker"
echo "   • Jenkins LTS"
echo ""
echo "✅ Jenkins is running at: http://localhost:8080"
if [ -f ~/.jenkins/secrets/initialAdminPassword ]; then
    ADMIN_PASSWORD=$(cat ~/.jenkins/secrets/initialAdminPassword)
    echo "✅ Admin password: ${ADMIN_PASSWORD}"
fi
if minikube status >/dev/null 2>&1 | grep -q "Running"; then
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "unknown")
    echo "✅ Minikube is running (IP: ${MINIKUBE_IP})"
fi
echo ""
echo "🚀 You're all set! Follow the next steps above to configure Jenkins."
echo ""
print_success "Setup script completed successfully!"
echo ""

