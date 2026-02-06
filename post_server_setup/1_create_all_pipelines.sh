#!/bin/bash
# 1_create_all_pipelines.sh - Create Jenkins pipelines for all projects
# Usage: ./1_create_all_pipelines.sh

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
source "${SCRIPT_DIR}/repos_config.sh"

JENKINS_CLI="${SCRIPT_DIR}/jenkins-cli.jar"

# Verify Jenkins connection
echo -e "${BLUE}Testing Jenkins connection...${NC}"
if ! java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" who-am-i &>/dev/null; then
    echo -e "${RED}Failed to connect to Jenkins${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected to Jenkins${NC}\n"

# Function to generate job XML
generate_job_xml() {
    local job_name=$1
    local git_url=$2
    local branch=${3:-main}
    
    cat <<EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <description>Auto-generated pipeline for ${job_name}</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <com.coravy.hudson.plugins.github.GithubProjectProperty plugin="github">
      <projectUrl>${git_url}</projectUrl>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>${git_url}</url>
          <credentialsId>${GITHUB_CRED_ID}</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/${branch}</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF
}

# Create pipelines for all repos
echo -e "${BLUE}Creating pipelines for all projects...${NC}\n"

SUCCESS_COUNT=0
FAIL_COUNT=0
SKIPPED_COUNT=0

while IFS='|' read -r repo_name git_url has_build has_deploy type; do
    # Skip empty lines and comments
    [[ -z "$repo_name" || "$repo_name" =~ ^# ]] && continue
    
    # Trim whitespace
    repo_name=$(echo "$repo_name" | xargs)
    git_url=$(echo "$git_url" | xargs)
    
    echo -e "${YELLOW}Processing: ${repo_name}${NC}"
    
    # Create build job if applicable
    if [ "$has_build" = "true" ]; then
        BUILD_JOB="${repo_name}_build"
        
        # Check if job exists
        if java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" get-job "$BUILD_JOB" &>/dev/null; then
            echo -e "  ${YELLOW}⊘ ${BUILD_JOB} already exists (skipped)${NC}"
            ((SKIPPED_COUNT++))
        else
            XML=$(generate_job_xml "$BUILD_JOB" "$git_url" "$DEFAULT_BRANCH")
            if echo "$XML" | java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" create-job "$BUILD_JOB" &>/dev/null; then
                echo -e "  ${GREEN}✓ Created ${BUILD_JOB}${NC}"
                ((SUCCESS_COUNT++))
            else
                echo -e "  ${RED}✗ Failed to create ${BUILD_JOB}${NC}"
                ((FAIL_COUNT++))
            fi
        fi
    fi
    
    # Create deploy job if applicable
    if [ "$has_deploy" = "true" ]; then
        DEPLOY_JOB="${repo_name}_deploy"
        
        if java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" get-job "$DEPLOY_JOB" &>/dev/null; then
            echo -e "  ${YELLOW}⊘ ${DEPLOY_JOB} already exists (skipped)${NC}"
            ((SKIPPED_COUNT++))
        else
            XML=$(generate_job_xml "$DEPLOY_JOB" "$git_url" "$DEFAULT_BRANCH")
            if echo "$XML" | java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" create-job "$DEPLOY_JOB" &>/dev/null; then
                echo -e "  ${GREEN}✓ Created ${DEPLOY_JOB}${NC}"
                ((SUCCESS_COUNT++))
            else
                echo -e "  ${RED}✗ Failed to create ${DEPLOY_JOB}${NC}"
                ((FAIL_COUNT++))
            fi
        fi
    fi
    
    echo ""
done <<< "$REPOS_LIST"

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Created: ${SUCCESS_COUNT}${NC}"
echo -e "${YELLOW}⊘ Skipped: ${SKIPPED_COUNT}${NC}"
echo -e "${RED}✗ Failed:  ${FAIL_COUNT}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $FAIL_COUNT -gt 0 ]; then
    exit 1
fi
