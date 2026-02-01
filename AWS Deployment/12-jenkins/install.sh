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
echo -e "${GREEN}Jenkins installed successfully!${NC}"
echo -e "Access: http://localhost:8080"
echo -e "Jenkins Home: $JENKINS_HOME"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Copy nginx config: sudo cp $(dirname $0)/nginx.conf /etc/nginx/sites-available/jenkins"
echo "2. Enable site: sudo ln -sf /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/"
echo "3. Test nginx: sudo nginx -t"
echo "4. Reload nginx: sudo systemctl reload nginx"
echo "5. Open https://jenkins.arpansahu.space and complete setup"
