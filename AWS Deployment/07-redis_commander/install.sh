#!/bin/bash

# Redis Commander Installation Script
# This script installs Redis Commander via npm and sets it up with PM2

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Redis Commander Installation${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo -e "${GREEN}✓ Loaded configuration from .env${NC}"
else
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please create .env from .env.example and configure your settings."
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed${NC}"
    echo "Please install Node.js first:"
    echo "  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
    echo "  sudo apt-get install -y nodejs"
    exit 1
fi

echo -e "${GREEN}Node.js version: $(node --version)${NC}"
echo -e "${GREEN}NPM version: $(npm --version)${NC}"
echo ""

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}PM2 not found. Installing PM2...${NC}"
    sudo npm install -g pm2
    echo -e "${GREEN}✓ PM2 installed${NC}"
else
    echo -e "${GREEN}✓ PM2 already installed: $(pm2 --version)${NC}"
fi

# Check if redis-commander is already installed
if ! command -v redis-commander &> /dev/null; then
    echo -e "${YELLOW}Redis Commander not found. Installing...${NC}"
    sudo npm install -g redis-commander
    echo -e "${GREEN}✓ Redis Commander installed${NC}"
else
    echo -e "${GREEN}✓ Redis Commander already installed${NC}"
    CURRENT_VERSION=$(redis-commander --version 2>&1 || echo "unknown")
    echo -e "${GREEN}  Version: ${CURRENT_VERSION}${NC}"
fi

# Stop existing redis-commander process if running
if pm2 list | grep -q "redis-commander"; then
    echo -e "${YELLOW}Stopping existing redis-commander process...${NC}"
    pm2 stop redis-commander 2>/dev/null || true
    pm2 delete redis-commander 2>/dev/null || true
    echo -e "${GREEN}✓ Stopped existing process${NC}"
fi

# Test Redis connection
echo -e "${GREEN}Testing Redis connection...${NC}"
if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" --no-auth-warning ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Redis connection successful${NC}"
else
    echo -e "${RED}✗ Cannot connect to Redis at ${REDIS_HOST}:${REDIS_PORT}${NC}"
    echo -e "${YELLOW}Please verify Redis is running and credentials are correct${NC}"
    exit 1
fi

# Start Redis Commander with PM2
echo -e "${GREEN}Starting Redis Commander with PM2...${NC}"

pm2 start redis-commander \
    --name redis-commander \
    -- \
    --redis-host "$REDIS_HOST" \
    --redis-port "$REDIS_PORT" \
    --redis-password "$REDIS_PASSWORD" \
    --port "$REDIS_COMMANDER_PORT" \
    --http-auth-username "$HTTP_AUTH_USERNAME" \
    --http-auth-password "$HTTP_AUTH_PASSWORD"

echo -e "${GREEN}✓ Redis Commander started${NC}"

# Wait for process to stabilize
echo -e "${GREEN}Waiting for process to stabilize...${NC}"
sleep 3

# Check if process is running
if pm2 list | grep -q "redis-commander.*online"; then
    echo -e "${GREEN}✓ Redis Commander is online${NC}"
else
    echo -e "${RED}✗ Redis Commander failed to start${NC}"
    echo "Check logs with: pm2 logs redis-commander"
    exit 1
fi

# Save PM2 process list
echo -e "${GREEN}Saving PM2 process list...${NC}"
pm2 save

# Setup PM2 startup script
echo -e "${GREEN}Configuring PM2 startup...${NC}"
STARTUP_CMD=$(pm2 startup | grep "sudo" | tail -1)
if [ -n "$STARTUP_CMD" ]; then
    echo -e "${YELLOW}Run this command to enable PM2 on boot:${NC}"
    echo -e "${YELLOW}$STARTUP_CMD${NC}"
    echo ""
    read -p "Do you want to run this command now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        eval "$STARTUP_CMD"
        pm2 save
        echo -e "${GREEN}✓ PM2 startup configured${NC}"
    else
        echo -e "${YELLOW}Skipped. Run the command manually later.${NC}"
    fi
fi

# Display process info
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
pm2 list
echo ""
echo -e "${GREEN}Redis Commander is running at:${NC}"
echo -e "  ${YELLOW}http://127.0.0.1:${REDIS_COMMANDER_PORT}${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo -e "  1. Run: ${YELLOW}sudo ./add-nginx-config.sh${NC}"
echo -e "  2. Access via: ${YELLOW}https://${DOMAIN}${NC}"
echo ""
echo -e "${GREEN}Useful PM2 commands:${NC}"
echo -e "  ${YELLOW}pm2 status${NC}           - View process status"
echo -e "  ${YELLOW}pm2 logs redis-commander${NC} - View logs"
echo -e "  ${YELLOW}pm2 restart redis-commander${NC} - Restart process"
echo -e "  ${YELLOW}pm2 stop redis-commander${NC} - Stop process"
echo ""
