# Jenkins Pipeline Creator

Automated Jenkins pipeline creation for all repositories. This tool creates build and deploy pipelines for all projects defined in `repos_config.sh`.

## Overview

After setting up Jenkins on a new server, use these scripts to automatically create all necessary pipelines. The scripts will:

1. Create a pipeline for the `common_readme` repository (README management)
2. Create build and deploy pipelines for all Django application repositories
3. Configure SCM polling and proper credentials
4. Use secure credential management (no hardcoded passwords in scripts)

## Prerequisites

### 1. Java 21 (Required for Jenkins CLI)

**macOS:**
```bash
brew install openjdk@21
echo 'export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
java -version
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install -y openjdk-21-jre
java -version
```

**Linux (Fedora/RHEL/CentOS):**
```bash
sudo dnf install -y java-21-openjdk
java -version
```

Or use the automated installer:
```bash
# In the parent directory (post_server_setup)
../jenkins_project_env/setup_prerequisites.sh
```

### 2. Jenkins Setup

- **Jenkins installed and running**
  - URL: https://jenkins.arpansahu.space
  - Admin user created
  - API token generated

- **Required Jenkins Credentials:**
  - `github_auth` - GitHub Personal Access Token with repo access

- **Jenkins Plugins Installed:**
  - Pipeline plugin
  - Git plugin
  - Workflow plugin
  - GitHub plugin

### 3. GitHub Access

- GitHub Personal Access Token with repository access
- Token added to Jenkins credentials as `github_auth`

## Setup

### Step 1: Configure Jenkins Credentials

1. Copy the example environment file:
   ```bash
   cp .env.jenkins.example .env.jenkins
   ```

2. Edit `.env.jenkins` with your Jenkins credentials:
   ```bash
   JENKINS_URL=https://jenkins.arpansahu.space
   JENKINS_USER=your_username
   JENKINS_API_TOKEN=your_api_token_here
   JENKINS_CLI=/tmp/jenkins-cli.jar
   ```

3. Generate Jenkins API Token:
   - Go to: Jenkins → User (top right) → Configure
   - Under "API Token", click "Add new Token"
   - Give it a name (e.g., "CLI Access")
   - Click "Generate"
   - Copy the token to `.env.jenkins`

**Note:** The `.env.jenkins` file is gitignored and will not be committed.

### Step 2: Configure Repositories

Edit `repos_config.sh` to add/remove repositories:

```bash
# Repository URLs
ALTERED_DATUM_API_REPO="https://github.com/arpansahu/altered_datum_api.git"
ARPANSAHU_DOT_ME_REPO="https://github.com/arpansahu/arpansahu_dot_me.git"
# ... add more repos

# Repository list with pipeline types
declare -A REPOS=(
    ["altered_datum_api"]="build deploy"
    ["arpansahu_dot_me"]="build deploy"
    ["common_readme"]="readme"
    # ... add more repos
)
```

## Usage

### Create All Pipelines

Run the main script to create all pipelines:

```bash
./create_jenkins_pipelines.sh
```

The script will:
1. ✅ Verify Jenkins CLI is available
2. ✅ Test connection to Jenkins server
3. ✅ Load repository configuration
4. ✅ Create/update each pipeline
5. ✅ Provide summary of created pipelines

### Expected Output

```
✓ Jenkins credentials loaded from .env.jenkins

[INFO] ========================================
[INFO] Jenkins Pipeline Creation Script
[INFO] ========================================

[INFO] Checking Jenkins CLI...
[SUCCESS] Jenkins CLI found at /tmp/jenkins-cli.jar

[INFO] Testing Jenkins connection...
[SUCCESS] Connected to Jenkins at https://jenkins.arpansahu.space

[INFO] ========================================
[INFO] Creating pipelines for all repositories
[INFO] ========================================

[INFO] Processing: altered_datum_api
  [INFO] Creating build pipeline: altered_datum_api-build...
  [SUCCESS] ✓ Created: altered_datum_api-build
  [INFO] Creating deploy pipeline: altered_datum_api-deploy...
  [SUCCESS] ✓ Created: altered_datum_api-deploy

[INFO] Processing: arpansahu_dot_me
  [INFO] Creating build pipeline: arpansahu_dot_me-build...
  [SUCCESS] ✓ Created: arpansahu_dot_me-build
  [INFO] Creating deploy pipeline: arpansahu_dot_me-deploy...
  [SUCCESS] ✓ Created: arpansahu_dot_me-deploy

[SUCCESS] ========================================
[SUCCESS] Pipeline Creation Complete!
[SUCCESS] Total pipelines created: 21
[SUCCESS] ========================================
```

### Remote Execution

Execute from your local machine:

```bash
# From common_readme directory
cd post_server_setup/jenkins_pipeline_creator

# Make scripts executable
chmod +x *.sh

# Run the script
./create_jenkins_pipelines.sh
```

Or execute on remote server:

```bash
# Copy to server
scp -r jenkins_pipeline_creator/ user@server:/tmp/

# Execute remotely
ssh user@server "cd /tmp/jenkins_pipeline_creator && chmod +x *.sh && ./create_jenkins_pipelines.sh"
```

## Files

### Configuration Files

- **`.env.jenkins`** - Jenkins API credentials (gitignored)
- **`.env.jenkins.example`** - Template for credentials file
- **`repos_config.sh`** - Repository configuration and list

### Scripts

- **`create_jenkins_pipelines.sh`** - Main automation script
  - Loads credentials from `.env.jenkins`
  - Checks Jenkins CLI availability
  - Creates/updates all pipelines
  - Provides colored output and progress tracking

- **`generate_job_xml.sh`** - XML generation functions
  - `generate_build_job_xml()` - Build pipeline XML
  - `generate_deploy_job_xml()` - Deploy pipeline XML
  - `generate_readme_job_xml()` - README pipeline XML

## Created Pipelines

The script creates the following pipelines:

### Django Applications (Build + Deploy)
- `altered_datum_api-build` / `altered_datum_api-deploy`
- `arpansahu_dot_me-build` / `arpansahu_dot_me-deploy`
- `borcelle_crm-build` / `borcelle_crm-deploy`
- `chew_and_cheer-build` / `chew_and_cheer-deploy`
- `clock_work-build` / `clock_work-deploy`
- `django_starter-build` / `django_starter-deploy`
- `great_chat-build` / `great_chat-deploy`
- `numerical-build` / `numerical-deploy`
- `school_chale_hum-build` / `school_chale_hum-deploy`
- `third_eye-build` / `third_eye-deploy`

### README Management
- `common_readme` - README management pipeline

**Total: 21 pipelines**

## Pipeline Features

### Build Pipelines
- Poll SCM every 5 minutes: `H/5 * * * *`
- Use `Jenkinsfile-build` from repository
- Pull from `main` branch
- Use GitHub credentials: `github_auth`

### Deploy Pipelines
- Poll SCM every 5 minutes: `H/5 * * * *`
- Use `Jenkinsfile-deploy` from repository
- Pull from `main` branch
- Use GitHub credentials: `github_auth`

### README Pipeline
- Poll SCM every 5 minutes: `H/5 * * * *`
- Use `Jenkinsfile` from repository
- Pull from `main` branch
- Use GitHub credentials: `github_auth`

## Adding New Repositories

To add a new repository:

1. **Edit `repos_config.sh`:**
   ```bash
   # Add repository URL
   NEW_PROJECT_REPO="https://github.com/username/new-project.git"
   
   # Add to REPOS array
   declare -A REPOS=(
       # ... existing repos ...
       ["new_project"]="build deploy"
   )
   ```

2. **Run the script:**
   ```bash
   ./create_jenkins_pipelines.sh
   ```

3. The script will create pipelines for the new repo and skip existing ones

## Troubleshooting

### Issue: "Cannot connect to Jenkins"

**Solution:**
- Verify Jenkins URL in `.env.jenkins`
- Check Jenkins is running: `curl -I https://jenkins.arpansahu.space`
- Verify API token is valid

### Issue: "Authentication failed (401)"

**Solution:**
- Regenerate Jenkins API token
- Update `.env.jenkins` with new token
- Verify username is correct

### Issue: "Jenkins CLI not found"

**Solution:**
- The script will download it automatically to `/tmp/jenkins-cli.jar`
- Or download manually:
  ```bash
  wget https://jenkins.arpansahu.space/jnlpJars/jenkins-cli.jar -O /tmp/jenkins-cli.jar
  ```

### Issue: "Job already exists"

**Note:** This is a warning, not an error. The script will update the existing job.

To force recreation:
1. Delete the job from Jenkins UI
2. Re-run the script

### Issue: Java not found

**Solution:**
- Install Java 21 (see Prerequisites section)
- Or run: `../jenkins_project_env/setup_prerequisites.sh`

## Security Notes

- ✅ Credentials stored in `.env.jenkins` (gitignored)
- ✅ No hardcoded passwords in scripts
- ✅ API tokens used instead of passwords
- ✅ GitHub credentials managed in Jenkins
- ❌ Never commit `.env.jenkins` to version control

## Integration with Jenkins

After pipeline creation, each repository's Jenkinsfile can access credentials:

```groovy
pipeline {
    agent any
    
    stages {
        stage('Setup Environment') {
            steps {
                withCredentials([string(credentialsId: 'project_name_env_file', variable: 'ENV_CONTENT')]) {
                    sh 'echo "$ENV_CONTENT" > .env'
                }
            }
        }
        
        stage('Build') {
            steps {
                // Your build steps
            }
        }
    }
}
```

## Related Tools

- **[jenkins_project_env](../jenkins_project_env/)** - Upload project .env files to Jenkins credentials
- **Post Server Setup** - Complete server setup automation

## Complete Setup Checklist

- [ ] 1. Install Java 21 (see Prerequisites)
- [ ] 2. Create `.env.jenkins` from example template
- [ ] 3. Generate Jenkins API token
- [ ] 4. Add GitHub Personal Access Token to Jenkins as `github_auth`
- [ ] 5. Configure repositories in `repos_config.sh`
- [ ] 6. Run `./create_jenkins_pipelines.sh`
- [ ] 7. Verify pipelines in Jenkins UI
- [ ] 8. Upload project .env files using `jenkins_project_env/upload_project_env.sh`
- [ ] 9. Test build and deploy pipelines

## Quick Start Summary

```bash
# 1. Setup credentials
cp .env.jenkins.example .env.jenkins
# Edit .env.jenkins with your credentials

# 2. Create all pipelines
./create_jenkins_pipelines.sh

# 3. Verify in Jenkins
# Visit: https://jenkins.arpansahu.space
```

That's it! All pipelines will be created automatically. 🚀
