# Quick Start - Jenkins Pipeline Creator

Create all Jenkins pipelines in 3 simple steps!

## Prerequisites ✅

- Java 21 installed (required for Jenkins CLI)
- Jenkins running at https://jenkins.arpansahu.space
- GitHub Personal Access Token added to Jenkins as `github_auth`

## Setup & Run

### Step 1: Configure Credentials

```bash
# Copy example file
cp .env.jenkins.example .env.jenkins

# Edit with your Jenkins credentials
nano .env.jenkins
```

Add your credentials:
```bash
JENKINS_URL=https://jenkins.arpansahu.space
JENKINS_USER=admin
JENKINS_API_TOKEN=your_api_token_here
JENKINS_CLI=/tmp/jenkins-cli.jar
```

**Get API Token:**
1. Go to Jenkins → People → admin → Configure
2. Option A: Click "Show Legacy API Token..." (recommended for CLI)
3. Option B: Under "API Token" → Click "Add new Token" → Generate
4. Copy token to `.env.jenkins`

### Step 2: Run the Script

```bash
# Make executable
chmod +x *.sh

# Create all pipelines
./create_jenkins_pipelines.sh
```

### Step 3: Verify

Visit Jenkins: https://jenkins.arpansahu.space

You should see **21 new pipelines** created! ✨

## What Gets Created?

### Django Projects (20 pipelines)
Each project gets 2 linked pipelines:
- **Build pipeline** (e.g., `altered_datum_api-build`) - Triggered by GitHub webhook
- **Deploy pipeline** (e.g., `altered_datum_api-deploy`) - Auto-triggered after successful build

**Projects:**
- altered_datum_api
- arpansahu_dot_me
- borcelle_crm
- chew_and_cheer
- clock_work
- django_starter
- great_chat
- numerical
- school_chale_hum
- third_eye

### README Management (1 pipeline)
- common_readme

## One-Liner (After .env.jenkins is configured)

```bash
./create_jenkins_pipelines.sh
```

## Expected Output

```
✓ Jenkins credentials loaded from .env.jenkins

[INFO] ========================================
[INFO] Jenkins Pipeline Creation Script
[INFO] ========================================

[INFO] Checking Jenkins CLI...
[SUCCESS] Jenkins CLI found at /tmp/jenkins-cli.jar

[INFO] Testing Jenkins connection...
[SUCCESS] Connected to Jenkins at https://jenkins.arpansahu.space

[INFO] Creating pipelines for all repositories...

[INFO] Processing: altered_datum_api
  [SUCCESS] ✓ Created: altered_datum_api-build
  [SUCCESS] ✓ Created: altered_datum_api-deploy

[INFO] Processing: arpansahu_dot_me
  [SUCCESS] ✓ Created: arpansahu_dot_me-build
  [SUCCESS] ✓ Created: arpansahu_dot_me-deploy

... (more repos) ...

[SUCCESS] ========================================
[SUCCESS] Pipeline Creation Complete!
[SUCCESS] Total pipelines created: 21
[SUCCESS] ========================================
```

## Remote Execution

Run from your local machine:

```bash
# From common_readme directory
cd post_server_setup/jenkins_pipeline_creator

# Setup credentials
cp .env.jenkins.example .env.jenkins
# Edit .env.jenkins

# Run
./create_jenkins_pipelines.sh
```

Or execute on remote server:

```bash
# Copy to server
scp -r jenkins_pipeline_creator/ user@server:/tmp/

# Execute remotely
ssh user@server "cd /tmp/jenkins_pipeline_creator && chmod +x *.sh && ./create_jenkins_pipelines.sh"
```

## Adding New Projects

1. Edit `repos_config.sh`:
   ```bash
   # Add new repository URL
   NEW_PROJECT_REPO="https://github.com/username/new-project.git"
   
   # Add to REPOS array
   declare -A REPOS=(
       # ... existing ...
       ["new_project"]="build deploy"
   )
   ```

2. Run the script again:
   ```bash
   ./create_jenkins_pipelines.sh
   ```

Existing pipelines will be skipped, only new ones created! 🎯

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **Cannot connect to Jenkins** | Check `JENKINS_URL` in `.env.jenkins` |
| **Authentication failed (401)** | Regenerate API token in Jenkins |
| **Jenkins CLI not found** | Script will download it automatically to `/tmp/jenkins-cli.jar` |
| **Java not found** | Install Java 21: `brew install openjdk@21` (macOS) or see README |
| **Job already exists** | Not an error! Script will update existing job |

## Security 🔒

- ✅ Credentials in `.env.jenkins` (gitignored)
- ✅ No hardcoded passwords
- ✅ API tokens instead of passwords
- ❌ **Never commit `.env.jenkins`**

## Next Steps

After creating pipelines:

1. **Setup GitHub Webhooks** for automatic builds:
   - Go to each GitHub repository → Settings → Webhooks
   - Add webhook: `https://jenkins.arpansahu.space/github-webhook/`
   - Content type: `application/json`
   - Events: "Just the push event"
   - See full instructions in [README.md](README.md#github-webhook-setup)

2. **Upload project .env files** to Jenkins:
   ```bash
   cd ../jenkins_project_env
   ./upload_project_env.sh
   ```

3. **Verify pipelines** in Jenkins UI

4. **Test the automated flow:**
   - Make a commit and push to any repository
   - Watch build job trigger automatically (via webhook)
   - Watch deploy job trigger automatically after build succeeds
   - Full CI/CD in action! 🚀

5. **Monitor** - Check Jenkins dashboard for build status

## Pipeline Flow

```
GitHub Push → Build Job (webhook) → Deploy Job (auto) → Production
     ↓              ↓                      ↓
   Instant      Build+Test            Auto Deploy
```

**How it works:**
1. Push code to GitHub
2. Webhook triggers build job instantly
3. Build job creates Docker image and pushes to Harbor
4. Deploy job automatically triggers on successful build
5. Deploy job pulls image and deploys to environment

**No manual steps needed!** ✨

## Complete Workflow

```bash
# 1. Install Java (if needed)
brew install openjdk@21

# 2. Configure credentials
cp .env.jenkins.example .env.jenkins
# Edit .env.jenkins

# 3. Create pipelines
./create_jenkins_pipelines.sh

# 4. Upload environment variables
cd ../jenkins_project_env
./upload_project_env.sh

# Done! 🚀
```

## Files in This Directory

- `create_jenkins_pipelines.sh` - Main script (creates all pipelines)
- `generate_job_xml.sh` - XML generation functions
- `repos_config.sh` - Repository configuration
- `.env.jenkins` - Your credentials (gitignored)
- `.env.jenkins.example` - Template file
- `README.md` - Full documentation
- `QUICK_START.md` - This file

## Need Help?

See the full [README.md](README.md) for:
- Detailed prerequisites
- Step-by-step installation
- Advanced configuration
- Pipeline customization
- Troubleshooting guide

---

**That's it!** Run the script and get 21 pipelines in seconds. ⚡
