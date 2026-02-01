#!/bin/bash

###############################################################################
# Setup Prerequisites for Jenkins Project Environment Manager
# 
# This script installs Java 21 which is required to run Jenkins CLI
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Jenkins Environment Manager - Prerequisites       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo -e "${YELLOW}Detected OS: ${MACHINE}${NC}\n"

# Check if Java is already installed
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' | cut -d'.' -f1)
    if [ "$JAVA_VERSION" -ge 21 ]; then
        echo -e "${GREEN}✓ Java ${JAVA_VERSION} is already installed${NC}"
        java -version
        echo ""
        echo -e "${GREEN}All prerequisites met!${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠ Java ${JAVA_VERSION} found, but Java 21+ is required${NC}\n"
    fi
fi

# Install Java based on OS
if [ "$MACHINE" = "Mac" ]; then
    echo -e "${YELLOW}Installing Java 21 on macOS...${NC}\n"
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}ERROR: Homebrew is not installed${NC}"
        echo -e "${YELLOW}Install Homebrew first:${NC}"
        echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        exit 1
    fi
    
    # Install OpenJDK 21
    echo -e "${BLUE}Installing openjdk@21...${NC}"
    brew install openjdk@21
    
    # Add to PATH
    SHELL_CONFIG=""
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    fi
    
    if [ -n "$SHELL_CONFIG" ]; then
        # Check if PATH already configured
        if ! grep -q 'openjdk@21/bin' "$SHELL_CONFIG" 2>/dev/null; then
            echo 'export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"' >> "$SHELL_CONFIG"
            echo -e "${GREEN}✓ Added Java to PATH in ${SHELL_CONFIG}${NC}"
        fi
    fi
    
    # Apply to current session
    export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
    
elif [ "$MACHINE" = "Linux" ]; then
    echo -e "${YELLOW}Installing Java 21 on Linux...${NC}\n"
    
    # Detect Linux distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo -e "${RED}ERROR: Cannot detect Linux distribution${NC}"
        exit 1
    fi
    
    case "$DISTRO" in
        ubuntu|debian)
            echo -e "${BLUE}Installing via apt...${NC}"
            sudo apt update
            sudo apt install -y openjdk-21-jre
            ;;
        fedora|rhel|centos)
            echo -e "${BLUE}Installing via dnf/yum...${NC}"
            sudo dnf install -y java-21-openjdk || sudo yum install -y java-21-openjdk
            ;;
        *)
            echo -e "${RED}ERROR: Unsupported Linux distribution: ${DISTRO}${NC}"
            echo -e "${YELLOW}Please install Java 21 manually${NC}"
            exit 1
            ;;
    esac
else
    echo -e "${RED}ERROR: Unsupported operating system: ${MACHINE}${NC}"
    exit 1
fi

# Verify installation
echo ""
echo -e "${YELLOW}Verifying Java installation...${NC}"
if command -v java &> /dev/null; then
    echo -e "${GREEN}✓ Java installed successfully!${NC}\n"
    java -version
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          Prerequisites Setup Complete!                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  1. Restart your terminal or run: source ~/.zshrc"
    echo -e "  2. Run: ./upload_project_env.sh"
else
    echo -e "${RED}✗ Java installation failed${NC}"
    exit 1
fi
