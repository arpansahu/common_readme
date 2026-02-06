#!/bin/bash
# 2_upload_env_interactive.sh - Upload/update Jenkins credentials interactively
# Usage: ./2_upload_env_interactive.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment
if [ ! -f "${SCRIPT_DIR}/.env.jenkins" ]; then
    echo -e "${RED}ERROR: .env.jenkins not found${NC}"
    exit 1
fi

source "${SCRIPT_DIR}/.env.jenkins"

JENKINS_CLI="${SCRIPT_DIR}/jenkins-cli.jar"

# Verify Jenkins connection
echo -e "${BLUE}Testing Jenkins connection...${NC}"
if ! java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" who-am-i &>/dev/null; then
    echo -e "${RED}Failed to connect to Jenkins${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected to Jenkins${NC}\n"

# Get credential ID
echo -e "${YELLOW}Enter credential ID (e.g., project_env):${NC}"
read -r CRED_ID

if [ -z "$CRED_ID" ]; then
    echo -e "${RED}Credential ID cannot be empty${NC}"
    exit 1
fi

# Get description
echo -e "${YELLOW}Enter description (optional):${NC}"
read -r DESCRIPTION

if [ -z "$DESCRIPTION" ]; then
    DESCRIPTION="Environment variables for $CRED_ID"
fi

# Get env file content
echo -e "${YELLOW}Paste your .env content (press Ctrl+D when done):${NC}"
ENV_CONTENT=$(cat)

if [ -z "$ENV_CONTENT" ]; then
    echo -e "${RED}Environment content cannot be empty${NC}"
    exit 1
fi

# Show preview
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Preview:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Credential ID: ${GREEN}${CRED_ID}${NC}"
echo -e "Description: ${GREEN}${DESCRIPTION}${NC}"
echo -e "Content lines: ${GREEN}$(echo "$ENV_CONTENT" | wc -l)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Confirm
echo -e "${YELLOW}Upload this credential? (y/n):${NC}"
read -r CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${YELLOW}Cancelled${NC}"
    exit 0
fi

# Create XML for secret file credential
XML=$(cat <<EOF
<org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>${CRED_ID}</id>
  <description>${DESCRIPTION}</description>
  <fileName>.env</fileName>
  <secretBytes>$(echo "$ENV_CONTENT" | base64)</secretBytes>
</org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl>
EOF
)

# Check if credential exists
if java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" get-credentials-as-xml system::system::jenkins "(global)" "$CRED_ID" &>/dev/null; then
    echo -e "${YELLOW}Credential exists. Updating...${NC}"
    
    if echo "$XML" | java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" update-credentials-by-xml system::system::jenkins "(global)" "$CRED_ID" 2>/dev/null; then
        echo -e "${GREEN}✓ Successfully updated credential: ${CRED_ID}${NC}"
    else
        echo -e "${RED}✗ Failed to update credential${NC}"
        exit 1
    fi
else
    echo -e "${BLUE}Creating new credential...${NC}"
    
    if echo "$XML" | java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" create-credentials-by-xml system::system::jenkins "(global)" 2>/dev/null; then
        echo -e "${GREEN}✓ Successfully created credential: ${CRED_ID}${NC}"
    else
        echo -e "${RED}✗ Failed to create credential${NC}"
        exit 1
    fi
fi
