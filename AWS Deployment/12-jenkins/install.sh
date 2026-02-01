#!/bin/bash
set -e

echo "=== Jenkins Installation Script ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
JENKINS_HOME="${JENKINS_HOME:-/var/lib/jenkins}"

echo -e "${YELLOW}Step 1: Installing Java${NC}"
sudo apt update
sudo apt install -y openjdk-17-jre

echo -e "${YELLOW}Step 2: Adding Jenkins Repository${NC}"
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

echo -e "${YELLOW}Step 3: Installing Jenkins${NC}"
sudo apt update
sudo apt install -y jenkins

echo -e "${YELLOW}Step 4: Starting Jenkins${NC}"
sudo systemctl enable jenkins
sudo systemctl start jenkins

echo -e "${YELLOW}Step 5: Waiting for Jenkins to start...${NC}"
sleep 15

echo -e "${YELLOW}Step 6: Getting Initial Admin Password${NC}"
echo -e "${GREEN}Initial Admin Password:${NC}"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

echo ""
echo -e "${YELLOW}Step 7: Configuring Jenkins Permissions${NC}"

# Configure sudoers for Jenkins
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_info "Setting up Jenkins permissions for CI/CD pipelines..."

# Create sudoers file for Jenkins
SUDOERS_FILE="/etc/sudoers.d/jenkins"

cat > "$SUDOERS_FILE" << 'EOF'
# Jenkins CI/CD permissions
# Allow Jenkins to manage Docker, Kubernetes, and services without password

# Jenkins user can manage Docker without password
jenkins ALL=(ALL) NOPASSWD: /usr/bin/docker
jenkins ALL=(ALL) NOPASSWD: /usr/bin/docker-compose

# Jenkins user can manage Kubernetes without password
jenkins ALL=(ALL) NOPASSWD: /usr/local/bin/kubectl
jenkins ALL=(ALL) NOPASSWD: /usr/bin/kubectl

# Jenkins user can restart services
jenkins ALL=(ALL) NOPASSWD: /bin/systemctl restart *
jenkins ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart *
EOF

# Set proper permissions
chmod 0440 "$SUDOERS_FILE"

# Validate sudoers file
if visudo -c -f "$SUDOERS_FILE" &>/dev/null; then
    log_info "✓ Sudoers configuration created successfully"
else
    echo -e "${YELLOW}[WARNING] Invalid sudoers configuration, removing...${NC}"
    rm -f "$SUDOERS_FILE"
fi

# Add Jenkins to docker group
if ! groups jenkins | grep -q docker 2>/dev/null; then
    usermod -aG docker jenkins
    log_info "✓ Added Jenkins user to docker group"
else
    log_info "✓ Jenkins user already in docker group"
fi

# Setup kubeconfig for Jenkins user (if kubectl is installed)
if command -v kubectl &> /dev/null; then
    log_info "Setting up Kubernetes configuration for Jenkins..."
    JENKINS_HOME_DIR="/var/lib/jenkins"
    KUBE_DIR="$JENKINS_HOME_DIR/.kube"
    mkdir -p "$KUBE_DIR"

    # If there's a root kubeconfig, copy it for Jenkins
    if [ -f "/root/.kube/config" ]; then
        cp /root/.kube/config "$KUBE_DIR/config"
        chown -R jenkins:jenkins "$KUBE_DIR"
        chmod 600 "$KUBE_DIR/config"
        log_info "✓ Copied kubeconfig for Jenkins user"
    elif [ -f "$HOME/.kube/config" ]; then
        cp "$HOME/.kube/config" "$KUBE_DIR/config"
        chown -R jenkins:jenkins "$KUBE_DIR"
        chmod 600 "$KUBE_DIR/config"
        log_info "✓ Copied kubeconfig for Jenkins user"
    else
        chown -R jenkins:jenkins "$KUBE_DIR"
        echo -e "${YELLOW}[WARNING] No kubeconfig found. Set it up after Kubernetes installation:${NC}"
        echo "  sudo cp ~/.kube/config $KUBE_DIR/config"
        echo "  sudo chown jenkins:jenkins $KUBE_DIR/config"
        echo "  sudo chmod 600 $KUBE_DIR/config"
    fi
else
    echo -e "${YELLOW}[INFO] kubectl not installed. Install Kubernetes first if you need K8s deployments.${NC}"
fi

# Restart Jenkins to apply group changes
sudo systemctl restart jenkins
log_info "✓ Jenkins restarted to apply permission changes"

echo ""
echo -e "${GREEN}Jenkins installed and configured successfully!${NC}"
echo -e "Access: http://localhost:8080"
echo -e "Jenkins Home: $JENKINS_HOME"
echo ""
echo -e "${GREEN}Permissions configured:${NC}"
echo "  ✓ Jenkins can run Docker commands"
echo "  ✓ Jenkins can run kubectl commands (if installed)"
echo "  ✓ Jenkins can restart services"
echo "  ✓ Jenkins is in docker group"
if command -v kubectl &> /dev/null; then
    echo "  ✓ Kubeconfig configured for Jenkins user"
fi
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Copy nginx config: sudo cp $(dirname $0)/nginx.conf /etc/nginx/sites-available/jenkins"
echo "2. Enable site: sudo ln -sf /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/"
echo "3. Test nginx: sudo nginx -t"
echo "4. Reload nginx: sudo systemctl reload nginx"
echo "5. Open https://jenkins.arpansahu.space and complete setup"
echo ""
echo -e "${YELLOW}For storing secrets:${NC}"
echo "Use Jenkins Credentials instead of .env files:"
echo "  Dashboard → Manage Jenkins → Credentials"
echo "  See: post_server_setup/jenkins_project_env/README.md"
