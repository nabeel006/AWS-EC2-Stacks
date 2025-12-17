#!/bin/bash

# EC2 Jenkins Setup Script for AKS Data Structures Project
# This script installs all prerequisites on an Ubuntu EC2 instance

set -e  # Exit on error

echo "=========================================="
echo "EC2 Jenkins Setup Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Check if running on Ubuntu
if [ ! -f /etc/lsb-release ]; then
    print_error "This script is designed for Ubuntu. Exiting."
    exit 1
fi

print_info "Detected OS: $(lsb_release -d | cut -f2)"
echo ""

# Step 1: Update system
print_info "Step 1: Updating system packages..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
print_success "System updated"
echo ""

# Step 2: Install Java
print_info "Step 2: Installing Java 17..."
if command -v java &> /dev/null; then
    print_success "Java already installed: $(java -version 2>&1 | head -n 1)"
else
    sudo apt-get install -y openjdk-17-jdk
    print_success "Java 17 installed"
fi
echo ""

# Step 3: Install Docker
print_info "Step 3: Installing Docker..."
if command -v docker &> /dev/null; then
    print_success "Docker already installed: $(docker --version)"
else
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    sudo usermod -aG docker $USER
    print_success "Docker installed"
    print_info "You need to log out and back in for Docker group changes to take effect"
fi
echo ""

# Step 4: Install Docker Compose
print_info "Step 4: Installing Docker Compose..."
if command -v docker-compose &> /dev/null; then
    print_success "Docker Compose already installed: $(docker-compose --version)"
else
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed"
fi
echo ""

# Step 5: Install Minikube
print_info "Step 5: Installing Minikube..."
if command -v minikube &> /dev/null; then
    print_success "Minikube already installed: $(minikube version --short)"
else
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    print_success "Minikube installed"
fi
echo ""

# Step 6: Install kubectl
print_info "Step 6: Installing kubectl..."
if command -v kubectl &> /dev/null; then
    print_success "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    print_success "kubectl installed"
fi
echo ""

# Step 7: Install Terraform
print_info "Step 7: Installing Terraform..."
if command -v terraform &> /dev/null; then
    print_success "Terraform already installed: $(terraform version | head -n 1)"
else
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update -qq
    sudo apt-get install -y terraform
    print_success "Terraform installed"
fi
echo ""

# Step 8: Install Git
print_info "Step 8: Installing Git..."
if command -v git &> /dev/null; then
    print_success "Git already installed: $(git --version)"
else
    sudo apt-get install -y git
    print_success "Git installed"
fi
echo ""

# Step 9: Install Jenkins
print_info "Step 9: Installing Jenkins..."
if [ -f /opt/jenkins/jenkins.war ]; then
    print_success "Jenkins WAR file already exists"
else
    sudo mkdir -p /opt/jenkins
    cd /opt/jenkins
    sudo wget -q https://get.jenkins.io/war-stable/latest/jenkins.war
    sudo chown -R $USER:$USER /opt/jenkins
    print_success "Jenkins downloaded"
fi
echo ""

# Step 10: Create Jenkins systemd service
print_info "Step 10: Creating Jenkins systemd service..."
if [ -f /etc/systemd/system/jenkins.service ]; then
    print_success "Jenkins service already exists"
else
    sudo tee /etc/systemd/system/jenkins.service > /dev/null <<EOF
[Unit]
Description=Jenkins Automation Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/jenkins
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
ExecStart=/usr/bin/java -jar /opt/jenkins/jenkins.war --httpPort=8080
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    print_success "Jenkins service created"
fi
echo ""

# Step 11: Start Jenkins
print_info "Step 11: Starting Jenkins..."
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins
print_success "Jenkins service started"
echo ""

# Step 12: Start Minikube
print_info "Step 12: Starting Minikube..."
if minikube status 2>/dev/null | grep -q "Running"; then
    print_success "Minikube is already running"
else
    # Check if user is in docker group
    if groups $USER | grep -q docker; then
        minikube start --driver=docker --memory=4096 --cpus=2
        print_success "Minikube started"
    else
        print_info "User not in docker group yet. Minikube will be started after re-login"
    fi
fi
echo ""

# Summary
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Installed components:"
echo "  ✓ Java:          $(java -version 2>&1 | head -n 1)"
echo "  ✓ Docker:        $(docker --version 2>/dev/null || echo 'Installed (requires re-login)')"
echo "  ✓ Minikube:      $(minikube version --short)"
echo "  ✓ kubectl:       $(kubectl version --client --short 2>/dev/null || echo 'Installed')"
echo "  ✓ Terraform:     $(terraform version | head -n 1)"
echo "  ✓ Git:           $(git --version)"
echo "  ✓ Jenkins:       Running on port 8080"
echo ""

# Wait for Jenkins to start
print_info "Waiting for Jenkins to start (this may take 1-2 minutes)..."
sleep 60

# Get Jenkins initial password
if [ -f ~/.jenkins/secrets/initialAdminPassword ]; then
    echo "=========================================="
    echo "Jenkins Initial Admin Password:"
    echo "=========================================="
    cat ~/.jenkins/secrets/initialAdminPassword
    echo ""
    echo "=========================================="
else
    print_info "Jenkins is still starting. Get the password later with:"
    echo "  cat ~/.jenkins/secrets/initialAdminPassword"
fi
echo ""

# Get EC2 public IP
EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")

echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo "1. Access Jenkins at: http://${EC2_IP}:8080"
echo "2. Use the initial admin password shown above"
echo "3. Install suggested plugins"
echo "4. Create admin user"
echo "5. Follow the EC2_JENKINS_SETUP_GUIDE.md for complete setup"
echo ""

if ! groups $USER | grep -q docker; then
    echo "=========================================="
    echo "IMPORTANT: Docker Group Change"
    echo "=========================================="
    print_info "You need to log out and back in for Docker group changes to take effect"
    echo "After re-login, start Minikube with:"
    echo "  minikube start --driver=docker --memory=4096 --cpus=2"
    echo ""
fi

echo "=========================================="
echo "Useful Commands:"
echo "=========================================="
echo "Check Jenkins status:    sudo systemctl status jenkins"
echo "Check Minikube status:   minikube status"
echo "Check kubectl:           kubectl get nodes"
echo "View Jenkins logs:       sudo journalctl -u jenkins -f"
echo ""

print_success "Setup complete! Follow EC2_JENKINS_SETUP_GUIDE.md for Jenkins configuration."
