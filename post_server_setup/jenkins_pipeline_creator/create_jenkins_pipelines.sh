#!/bin/bash
# create_jenkins_pipelines.sh - Automated Jenkins pipeline creation for all repositories
# This script creates Jenkins jobs for all repositories defined in repos_config.sh

# Note: Not using 'set -e' to handle job creation errors gracefully

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load Jenkins credentials from .env file
ENV_FILE="${SCRIPT_DIR}/.env.jenkins"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}ERROR: Jenkins credentials file not found: ${ENV_FILE}${NC}"
    echo -e "${YELLOW}Please create .env.jenkins with Jenkins API credentials${NC}"
    echo -e "${YELLOW}Copy .env.jenkins.example to .env.jenkins and fill in your credentials${NC}"
    exit 1
fi

source "$ENV_FILE"

# Validate Jenkins credentials
if [ -z "$JENKINS_URL" ] || [ -z "$JENKINS_USER" ] || [ -z "$JENKINS_API_TOKEN" ]; then
    echo -e "${RED}ERROR: Missing Jenkins credentials in .env.jenkins${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Jenkins credentials loaded from .env.jenkins${NC}\n"

# Source configuration files
source "${SCRIPT_DIR}/repos_config.sh"
source "${SCRIPT_DIR}/generate_job_xml.sh"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Jenkins CLI is available
check_jenkins_cli() {
    log_info "Checking Jenkins CLI..."
    
    if [ ! -f "$JENKINS_CLI" ]; then
        log_warning "Jenkins CLI not found. Downloading..."
        wget -q "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" -O "$JENKINS_CLI"
        
        if [ $? -eq 0 ]; then
            log_success "Jenkins CLI downloaded successfully"
        else
            log_error "Failed to download Jenkins CLI"
            exit 1
        fi
    else
        log_success "Jenkins CLI found at $JENKINS_CLI"
    fi
}

# Check if Jenkins is accessible
check_jenkins_connection() {
    log_info "Checking Jenkins connection..."
    
    if java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" who-am-i &>/dev/null; then
        log_success "Successfully connected to Jenkins"
    else
        log_error "Failed to connect to Jenkins. Please check credentials and Jenkins URL"
        exit 1
    fi
}

# Create a Jenkins job
create_jenkins_job() {
    local job_name=$1
    local xml_content=$2
    
    log_info "Creating job: $job_name"
    
    # Write XML to temporary file
    local temp_xml="/tmp/${job_name}_job.xml"
    echo "$xml_content" > "$temp_xml"
    
    # Try to create the job
    if cat "$temp_xml" | java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" create-job "$job_name" 2>/dev/null; then
        log_success "Created job: $job_name"
        rm -f "$temp_xml"
        return 0
    else
        # Job might already exist, try to update it
        if cat "$temp_xml" | java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" update-job "$job_name" 2>/dev/null; then
            log_warning "Updated existing job: $job_name"
            rm -f "$temp_xml"
            return 0
        else
            log_error "Failed to create/update job: $job_name"
            rm -f "$temp_xml"
            return 1
        fi
    fi
}

# Process a single repository
process_repository() {
    local repo_name=$1
    local repo_info=$2
    
    # Parse repo info: git_url|has_build|has_deploy|type
    IFS='|' read -r git_url has_build has_deploy repo_type <<< "$repo_info"
    
    log_info "Processing repository: $repo_name"
    log_info "  URL: $git_url"
    log_info "  Type: $repo_type"
    log_info "  Has Build: $has_build"
    log_info "  Has Deploy: $has_deploy"
    
    local success_count=0
    local total_jobs=0
    
    # Handle special case for common_readme
    if [ "$repo_type" = "readme_management" ]; then
        ((total_jobs++))
        xml_content=$(generate_readme_job_xml "$repo_name" "$git_url" "$DEFAULT_BRANCH")
        if create_jenkins_job "$repo_name" "$xml_content"; then
            ((success_count++))
        fi
    else
        # Create build job if needed
        if [ "$has_build" = "true" ]; then
            ((total_jobs++))
            local build_job_name="${repo_name}_build"
            xml_content=$(generate_build_job_xml "$build_job_name" "$git_url" "$DEFAULT_BRANCH" "Jenkinsfile-build")
            if create_jenkins_job "$build_job_name" "$xml_content"; then
                ((success_count++))
            fi
        fi
        
        # Create deploy job if needed
        if [ "$has_deploy" = "true" ]; then
            ((total_jobs++))
            local deploy_job_name="${repo_name}_deploy"
            xml_content=$(generate_deploy_job_xml "$deploy_job_name" "$git_url" "$DEFAULT_BRANCH" "Jenkinsfile-deploy")
            if create_jenkins_job "$deploy_job_name" "$xml_content"; then
                ((success_count++))
            fi
        fi
    fi
    
    if [ $success_count -eq $total_jobs ]; then
        log_success "Completed $repo_name: $success_count/$total_jobs jobs created/updated"
        return 0
    else
        log_warning "Completed $repo_name: $success_count/$total_jobs jobs created/updated"
        return 1
    fi
}

# Main execution
main() {
    echo ""
    log_info "========================================"
    log_info "Jenkins Pipeline Creation Script"
    log_info "========================================"
    echo ""
    
    # Pre-flight checks
    check_jenkins_cli
    check_jenkins_connection
    
    echo ""
    log_info "Starting pipeline creation for all repositories..."
    echo ""
    
    local total_repos=0
    local successful_repos=0
    local failed_repos=0
    
    # Process common_readme first
    if [ -n "${REPOS[common_readme]}" ]; then
        ((total_repos++))
        if process_repository "common_readme" "${REPOS[common_readme]}"; then
            ((successful_repos++))
        else
            ((failed_repos++))
        fi
        echo ""
    fi
    
    # Process all other repositories
    for repo_name in "${!REPOS[@]}"; do
        if [ "$repo_name" != "common_readme" ]; then
            ((total_repos++))
            if process_repository "$repo_name" "${REPOS[$repo_name]}"; then
                ((successful_repos++))
            else
                ((failed_repos++))
            fi
            echo ""
        fi
    done
    
    # Summary
    echo ""
    log_info "========================================"
    log_info "Summary"
    log_info "========================================"
    log_info "Total repositories processed: $total_repos"
    log_success "Successful: $successful_repos"
    if [ $failed_repos -gt 0 ]; then
        log_error "Failed: $failed_repos"
    fi
    echo ""
    
    # List all created jobs
    log_info "Listing all Jenkins jobs:"
    java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth "${JENKINS_USER}:${JENKINS_API_TOKEN}" list-jobs
    
    echo ""
    log_success "Pipeline creation completed!"
    log_info "Access Jenkins at: ${JENKINS_URL/localhost:8080/jenkins.arpansahu.space}"
    echo ""
}

# Run main function
main "$@"
