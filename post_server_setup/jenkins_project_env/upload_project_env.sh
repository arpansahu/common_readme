#!/bin/bash

###############################################################################
# Upload Project .env to Jenkins
# 
# Interactive script to upload/update .env file for any project
# Reads Jenkins credentials from .env.jenkins
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
JENKINS_CLI="${SCRIPT_DIR}/jenkins-cli.jar"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Upload Project .env to Jenkins Credentials        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"

# Load Jenkins credentials
ENV_FILE="${SCRIPT_DIR}/.env.jenkins"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}ERROR: Jenkins credentials file not found: ${ENV_FILE}${NC}"
    echo -e "${YELLOW}Please create .env.jenkins with Jenkins API credentials${NC}"
    exit 1
fi

source "$ENV_FILE"

# Remove trailing slash from JENKINS_URL if present
JENKINS_URL="${JENKINS_URL%/}"

# Validate Jenkins credentials loaded
if [ -z "$JENKINS_URL" ] || [ -z "$JENKINS_USER" ] || [ -z "$JENKINS_API_TOKEN" ]; then
    echo -e "${RED}ERROR: Missing Jenkins credentials in .env.jenkins${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Jenkins credentials loaded${NC}\n"

# Check Jenkins connectivity
echo -e "${YELLOW}Checking Jenkins connectivity...${NC}"
if ! curl -s -I -u "${JENKINS_USER}:${JENKINS_API_TOKEN}" "${JENKINS_URL}" | grep -iq "x-jenkins"; then
    echo -e "${RED}ERROR: Cannot connect to Jenkins at ${JENKINS_URL}${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected to Jenkins${NC}\n"

# Download Jenkins CLI if not present
if [ ! -f "$JENKINS_CLI" ]; then
    echo -e "${YELLOW}Downloading Jenkins CLI...${NC}"
    curl -s "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" -o "$JENKINS_CLI"
    echo -e "${GREEN}✓ Jenkins CLI downloaded${NC}\n"
fi

# Define project list (matches repos_config.sh)
PROJECTS=(
    "altered_datum_api"
    "arpansahu_dot_me"
    "borcelle_crm"
    "chew_and_cheer"
    "clock_work"
    "common_readme"
    "django_starter"
    "great_chat"
    "numerical"
    "school_chale_hum"
    "third_eye"
)

# Ask for project name
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Step 1: Select Project${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Display projects with numbers
for i in "${!PROJECTS[@]}"; do
    printf "%2d) %s\n" $((i+1)) "${PROJECTS[$i]}"
done

echo ""
read -p "Select project number (1-${#PROJECTS[@]}): " PROJECT_NUM

# Validate input
if ! [[ "$PROJECT_NUM" =~ ^[0-9]+$ ]] || [ "$PROJECT_NUM" -lt 1 ] || [ "$PROJECT_NUM" -gt "${#PROJECTS[@]}" ]; then
    echo -e "${RED}ERROR: Invalid selection${NC}"
    exit 1
fi

# Get project name from selection
PROJECT_NAME="${PROJECTS[$((PROJECT_NUM-1))]}"

echo -e "\n${GREEN}✓ Project: ${PROJECT_NAME}${NC}\n"

# Ask for .env content
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Step 2: Paste .env File Content${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Paste your .env file content below.${NC}"
echo -e "${BLUE}When done, press Ctrl+D (EOF) on a new line.${NC}\n"
echo -e "${YELLOW}Waiting for input...${NC}\n"

# Read multi-line input
TEMP_ENV_FILE="/tmp/${PROJECT_NAME}_$(date +%s).env"
cat > "$TEMP_ENV_FILE"

# Check if file has content
if [ ! -s "$TEMP_ENV_FILE" ]; then
    echo -e "\n${RED}ERROR: No content provided${NC}"
    rm -f "$TEMP_ENV_FILE"
    exit 1
fi

LINE_COUNT=$(wc -l < "$TEMP_ENV_FILE")
echo -e "\n${GREEN}✓ Received ${LINE_COUNT} lines${NC}\n"

# Show preview
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Preview of .env content (first 10 lines):${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
head -n 10 "$TEMP_ENV_FILE"
if [ "$LINE_COUNT" -gt 10 ]; then
    echo "..."
    echo -e "${BLUE}(${LINE_COUNT} total lines)${NC}"
fi
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Confirm upload
read -p "Upload this to Jenkins as '${PROJECT_NAME}_env_file'? (y/n): " CONFIRM || CONFIRM="y"
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Upload cancelled${NC}"
    rm -f "$TEMP_ENV_FILE"
    exit 0
fi

echo ""

# Create credential XML
echo -e "${YELLOW}Step 3: Uploading to Jenkins...${NC}"

CRED_ID="${PROJECT_NAME}_env_file"
CREDENTIAL_XML="/tmp/credential_${PROJECT_NAME}_$(date +%s).xml"

# Use Python to create proper XML with CDATA escaping
python3 << PYTHON_EOF > "$CREDENTIAL_XML"
import xml.etree.ElementTree as ET
from datetime import datetime

# Read the env file content
with open("${TEMP_ENV_FILE}", "r") as f:
    secret_content = f.read()

# Create XML structure
root = ET.Element("org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl")
scope = ET.SubElement(root, "scope")
scope.text = "GLOBAL"
cred_id = ET.SubElement(root, "id")
cred_id.text = "${CRED_ID}"
desc = ET.SubElement(root, "description")
desc.text = f".env file for ${PROJECT_NAME} (Uploaded: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')})"
secret = ET.SubElement(root, "secret")
secret.text = secret_content

# Output XML
print('<?xml version="1.0" encoding="UTF-8"?>')
print(ET.tostring(root, encoding='unicode'))
PYTHON_EOF

# Try to update first, if fails then create
ERROR_OUTPUT=$(mktemp)
if java -jar "${JENKINS_CLI}" -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" \
    update-credentials-by-xml system::system::jenkins _ "${CRED_ID}" < "$CREDENTIAL_XML" 2>"$ERROR_OUTPUT"; then
    echo -e "${GREEN}✓ Credential UPDATED: ${CRED_ID}${NC}"
    ACTION="updated"
elif java -jar "${JENKINS_CLI}" -s "${JENKINS_URL}" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" \
    create-credentials-by-xml system::system::jenkins _ < "$CREDENTIAL_XML" 2>"$ERROR_OUTPUT"; then
    echo -e "${GREEN}✓ Credential CREATED: ${CRED_ID}${NC}"
    ACTION="created"
else
    echo -e "${RED}✗ Failed to upload credential${NC}"
    echo -e "${RED}Error details:${NC}"
    cat "$ERROR_OUTPUT"
    rm -f "$TEMP_ENV_FILE" "$CREDENTIAL_XML" "$ERROR_OUTPUT"
    exit 1
fi

rm -f "$ERROR_OUTPUT"

# Cleanup
rm -f "$TEMP_ENV_FILE" "$CREDENTIAL_XML"

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  Upload Complete!                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${BLUE}Credential ID:${NC} ${CRED_ID}"
echo -e "${BLUE}Action:${NC} ${ACTION}"
echo -e "${BLUE}Verify at:${NC} ${JENKINS_URL}/credentials/\n"

echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Use in Jenkinsfile:"
echo -e "     ${CYAN}withCredentials([string(credentialsId: '${CRED_ID}', variable: 'ENV_CONTENT')]) {${NC}"
echo -e "     ${CYAN}    sh 'echo \"\$ENV_CONTENT\" > .env'${NC}"
echo -e "     ${CYAN}}${NC}"
echo -e ""
echo -e "  2. Trigger a build to test"
echo -e ""
