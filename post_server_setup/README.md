# Post Server Setup - Automation Tools

This directory contains automation tools for Jenkins setup and management after deploying a new server.

## Tools

### 1. [jenkins_pipeline_creator](jenkins_pipeline_creator/)

**Automated Jenkins pipeline creation** for all repositories.

Creates build and deploy pipelines for all projects with secure credential management.

**Quick Start:**
```bash
cd jenkins_pipeline_creator
cp .env.jenkins.example .env.jenkins
# Edit .env.jenkins with your credentials
./create_jenkins_pipelines.sh
```

**Features:**
- Creates 21 pipelines automatically
- Secure credential storage (gitignored `.env.jenkins`)
- Build + Deploy pipelines for all Django apps
- README management pipeline
- SCM polling configuration

See [jenkins_pipeline_creator/README.md](jenkins_pipeline_creator/README.md) for details.

### 2. [jenkins_project_env](jenkins_project_env/)

**Upload project environment variables** to Jenkins credentials.

Interactive tool to securely upload `.env` files as Jenkins credentials for use in pipelines.

**Quick Start:**
```bash
cd jenkins_project_env
cp .env.jenkins.example .env.jenkins
# Edit .env.jenkins with your credentials
./upload_project_env.sh
```

**Features:**
- Interactive menu for project selection
- Secure credential upload via Jenkins CLI
- Multi-line .env file support
- Proper XML escaping for special characters
- No credentials in version control

See [jenkins_project_env/README.md](jenkins_project_env/README.md) for details.

## Overview

After setting up Jenkins on a new server, use these scripts to automatically create all necessary pipelines for your repositories. The scripts will:

1. Create a pipeline for the `common_readme` repository (README management)
2. Create linked build and deploy pipelines for all Django application repositories
3. Configure GitHub webhook triggers for build jobs
4. Configure automatic deploy triggers after successful builds
5. Setup secure credential management

**Automated CI/CD Flow:**
- Push code → Build (instant via webhook) → Deploy (auto on success) → Production

## Files

### 1. `repos_config.sh`
Configuration file containing:
- List of all repositories with their Git URLs
- Pipeline types (build/deploy) for each repo
- Jenkins server configuration
- GitHub credentials ID

### 2. `generate_job_xml.sh`
Functions to generate Jenkins job XML configurations:
- `generate_build_job_xml()` - Creates build pipeline XML
- `generate_deploy_job_xml()` - Creates deployment pipeline XML
- `generate_readme_job_xml()` - Creates README management pipeline XML

### 3. `create_jenkins_pipelines.sh`
Main automation script that:
- Checks Jenkins CLI availability
- Connects to Jenkins server
- Creates/updates all pipelines
- Provides colored output and progress tracking

## Workflow

Complete setup process after deploying Jenkins on a new server:

### Step 1: Install Prerequisites

Both tools require **Java 21** for Jenkins CLI:

```bash
# macOS
brew install openjdk@21
echo 'export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Linux (Ubuntu/Debian)
sudo apt update && sudo apt install -y openjdk-21-jre

# Or use automated installer
cd jenkins_project_env
./setup_prerequisites.sh
```

### Step 2: Create Jenkins Pipelines

Create all build and deploy pipelines automatically:

```bash
cd jenkins_pipeline_creator

# Configure credentials
cp .env.jenkins.example .env.jenkins
# Edit .env.jenkins with Jenkins URL, username, and API token

# Create all pipelines
./create_jenkins_pipelines.sh
```

This creates **21 pipelines** (build + deploy for 10 projects + README management).

### Step 3: Setup GitHub Webhooks

Configure webhooks for automatic builds (instead of polling):

**For each repository:**
1. Go to GitHub: **Repository → Settings → Webhooks**
2. Click **Add webhook**
3. Configure:
   - **Payload URL:** `https://jenkins.arpansahu.space/github-webhook/`
   - **Content type:** `application/json`
   - **Events:** "Just the push event"
   - **Active:** ✓ Checked
4. Click **Add webhook**

See [jenkins_pipeline_creator/README.md](jenkins_pipeline_creator/README.md#github-webhook-setup) for details.

### Step 4: Upload Environment Variables

Upload project `.env` files to Jenkins credentials:

```bash
cd ../jenkins_project_env

# Configure credentials (same as step 2 if already done)
cp .env.jenkins.example .env.jenkins
# Edit .env.jenkins

# Upload .env files interactively
./upload_project_env.sh
```

Select project, paste `.env` content, and it's securely stored in Jenkins.

### Step 5: Verify

1. Visit Jenkins: https://jenkins.arpansahu.space
2. Check pipelines are created
3. Verify credentials in Jenkins → Credentials
4. Make a test commit to verify webhook triggers build automatically
4. Trigger a test build

## Prerequisites

### Jenkins Setup

1. **Jenkins installed and running**
   - URL: https://jenkins.arpansahu.space
   - Admin user created
   - API token generated

2. **Required Jenkins Credentials**
   - `github_auth` - GitHub Personal Access Token with repo access

3. **Jenkins Plugins Installed**
   - Pipeline plugin
   - Git plugin
   - Workflow plugin
   - GitHub plugin
   - Credentials Binding plugin

### Local Machine

- **Java 21** - Required for Jenkins CLI
- **SSH Access** - To connect to server (if running remotely)
- **Git** - To clone repositories

## Additional Tools

### install_kubectl.sh

Installs kubectl for Kubernetes cluster management.

```bash
./install_kubectl.sh
```

### Other Documentation

- [JENKINS_PERMISSIONS_FIX.md](JENKINS_PERMISSIONS_FIX.md) - Fix Docker permissions in Jenkins
- [QUICK_START.md](QUICK_START.md) - Legacy quick start (deprecated - use subdirectory tools)

## Remote Execution

### Execute Pipeline Creator Remotely

```bash
# Copy to server
scp -r post_server_setup/jenkins_pipeline_creator/ user@server:/tmp/

# Execute on server
ssh user@server "cd /tmp/jenkins_pipeline_creator && chmod +x *.sh && ./create_jenkins_pipelines.sh"
```

### Execute from Local Machine

Both tools can run from your local machine as long as:
- Jenkins is accessible at the configured URL
- You have the API token
- Java 21 is installed locally

```bash
# From your local machine
cd post_server_setup/jenkins_pipeline_creator
./create_jenkins_pipelines.sh

cd ../jenkins_project_env
./upload_project_env.sh
```

## Security Best Practices

✅ **DO:**
- Store credentials in `.env.jenkins` files
- Keep `.env.jenkins` gitignored
- Use Jenkins API tokens (not passwords)
- Regenerate API tokens periodically
- Restrict Jenkins credential access

❌ **DON'T:**
- Commit `.env.jenkins` files
- Hardcode credentials in scripts
- Share API tokens in chat/email
- Use plain passwords instead of tokens
- Store credentials in version control

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **Cannot connect to Jenkins** | Verify `JENKINS_URL` in `.env.jenkins` is correct |
| **Authentication failed (401)** | Regenerate Jenkins API token and update `.env.jenkins` |
| **Jenkins CLI not found** | Scripts download automatically to `/tmp/jenkins-cli.jar` |
| **Java not found** | Install Java 21 (see Prerequisites) |
| **Permission denied** | Make scripts executable: `chmod +x *.sh` |

### Debug Mode

Run scripts with bash debug flag:

```bash
bash -x ./create_jenkins_pipelines.sh
bash -x ./upload_project_env.sh
```

## Complete Setup Checklist

- [ ] 1. **Install Java 21** (`brew install openjdk@21` or use `setup_prerequisites.sh`)
- [ ] 2. **Generate Jenkins API Token** (Jenkins → User → Configure → API Token)
- [ ] 3. **Add GitHub Token to Jenkins** (as `github_auth` credential)
- [ ] 4. **Create Pipelines:**
  - [ ] Configure `jenkins_pipeline_creator/.env.jenkins`
  - [ ] Run `./create_jenkins_pipelines.sh`
  - [ ] Verify 21 pipelines created in Jenkins
- [ ] 5. **Setup GitHub Webhooks:**
  - [ ] Add webhook to each repository
  - [ ] URL: `https://jenkins.arpansahu.space/github-webhook/`
  - [ ] Verify green checkmark after first ping
- [ ] 6. **Upload Environment Variables:**
  - [ ] Configure `jenkins_project_env/.env.jenkins` (if different)
  - [ ] Run `./upload_project_env.sh` for each project
  - [ ] Verify credentials in Jenkins → Credentials
- [ ] 7. **Test Builds:**
  - [ ] Make a test commit to any repository
  - [ ] Verify webhook triggers build job automatically
  - [ ] Verify deploy job triggers automatically after successful build
  - [ ] Check .env file is created in build
  - [ ] Verify deployment completes successfully
  - [ ] Full CI/CD pipeline working end-to-end!

## Directory Structure

```
post_server_setup/
├── README.md                          # This file
├── QUICK_START.md                     # Legacy quick start (deprecated)
├── JENKINS_PERMISSIONS_FIX.md         # Docker permissions fix
├── install_kubectl.sh                 # Kubectl installer
│
├── jenkins_pipeline_creator/          # ✅ Pipeline creation tool
│   ├── README.md                      # Full documentation
│   ├── QUICK_START.md                 # Quick start guide
│   ├── .env.jenkins.example           # Credential template
│   ├── .env.jenkins                   # Your credentials (gitignored)
│   ├── create_jenkins_pipelines.sh    # Main script
│   ├── generate_job_xml.sh            # XML generator
│   └── repos_config.sh                # Repository config
│
├── jenkins_project_env/               # ✅ Env upload tool
│   ├── README.md                      # Full documentation
│   ├── QUICK_START.md                 # Quick start guide
│   ├── .env.jenkins.example           # Credential template
│   ├── .env.jenkins                   # Your credentials (gitignored)
│   ├── upload_project_env.sh          # Main script
│   └── setup_prerequisites.sh         # Java installer
```

## Quick Reference

### Create All Pipelines
```bash
cd jenkins_pipeline_creator
./create_jenkins_pipelines.sh
```

### Upload .env File
```bash
cd jenkins_project_env
./upload_project_env.sh
```

### Install Prerequisites
```bash
cd jenkins_project_env
./setup_prerequisites.sh
```

### Verify Setup
```bash
# Check Java
java -version

# Check Jenkins connection
curl -I -u username:token https://jenkins.arpansahu.space

# List Jenkins jobs
java -jar /tmp/jenkins-cli.jar -s https://jenkins.arpansahu.space -auth username:token list-jobs
```

---

**For detailed documentation, see the README in each subdirectory:**
- [jenkins_pipeline_creator/README.md](jenkins_pipeline_creator/README.md)
- [jenkins_project_env/README.md](jenkins_project_env/README.md)

