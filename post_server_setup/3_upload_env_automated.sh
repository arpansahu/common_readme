#!/bin/bash
# 3_upload_env_automated.sh - Upload/update Jenkins credentials (non-interactive)
# Usage: ./3_upload_env_automated.sh <credential_id> <env_file_path> [description]
# Example: ./3_upload_env_automated.sh django_starter_env /path/to/.env "Django Starter Environment"

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
CRED_ID="$1"
ENV_FILE_PATH="$2"
DESCRIPTION="${3:-Environment variables for $CRED_ID}"

# Validate arguments
if [ -z "$CRED_ID" ]; then
    echo -e "${RED}ERROR: Credential ID not provided${NC}"
    echo -e "${YELLOW}Usage: $0 <credential_id> <env_file_path> [description]${NC}"
    exit 1
fi

if [ -z "$ENV_FILE_PATH" ]; then
    echo -e "${RED}ERROR: Environment file path not provided${NC}"
    echo -e "${YELLOW}Usage: $0 <credential_id> <env_file_path> [description]${NC}"
    exit 1
fi

if [ ! -f "$ENV_FILE_PATH" ]; then
    echo -e "${RED}ERROR: Environment file not found: ${ENV_FILE_PATH}${NC}"
    exit 1
fi

# Load Jenkins config
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

# Read env file
ENV_CONTENT=$(cat "$ENV_FILE_PATH")

if [ -z "$ENV_CONTENT" ]; then
    echo -e "${RED}ERROR: Environment file is empty${NC}"
    exit 1
fi

# Show info
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Credential ID: ${GREEN}${CRED_ID}${NC}"
echo -e "Source file: ${GREEN}${ENV_FILE_PATH}${NC}"
echo -e "Description: ${GREEN}${DESCRIPTION}${NC}"
echo -e "Content lines: ${GREEN}$(echo "$ENV_CONTENT" | wc -l)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

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

echo -e "\n${GREEN}✓ Operation completed successfully${NC}"
