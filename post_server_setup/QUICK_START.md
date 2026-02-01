# Quick Start Guide - Post Server Setup

⚠️ **Note:** This quick start is deprecated. Please use the tool-specific quick starts:
- [jenkins_pipeline_creator/QUICK_START.md](jenkins_pipeline_creator/QUICK_START.md) - Create Jenkins pipelines
- [jenkins_project_env/QUICK_START.md](jenkins_project_env/QUICK_START.md) - Upload environment variables

## Modern Workflow

### Step 1: Create Jenkins Pipelines

```bash
cd jenkins_pipeline_creator
cp .env.jenkins.example .env.jenkins
# Edit .env.jenkins with your credentials
./create_jenkins_pipelines.sh
```

**Result:** 21 pipelines created automatically

### Step 2: Upload Environment Variables

```bash
cd ../jenkins_project_env
cp .env.jenkins.example .env.jenkins
# Edit .env.jenkins (can reuse same credentials)
./upload_project_env.sh
```

**Result:** Project .env files securely stored in Jenkins

## Full Documentation

See the main [README.md](README.md) for:
- Complete setup instructions
- Prerequisites (Java 21)
- Troubleshooting guide
- Security best practices

---

# Legacy Content (Deprecated)

The content below is kept for reference but refers to old scripts that have been moved to subdirectories.

## ✅ Successfully Created Pipelines

**Total: 21 Jenkins pipelines**

- 1 README management pipeline (common_readme)
- 20 application pipelines (10 repos × 2 pipelines each)

## Created Pipelines List

### README Management
1. `common_readme` - Updates README files across all projects

### Django Applications (Build + Deploy)
2. `arpansahu_dot_me_build` / `arpansahu_dot_me_deploy`
3. `borcelle_crm_build` / `borcelle_crm_deploy`
4. `chew_and_cheer_build` / `chew_and_cheer_deploy`
5. `clock_work_build` / `clock_work_deploy`
6. `django_starter_build` / `django_starter_deploy`
7. `great_chat_build` / `great_chat_deploy`
8. `numerical_build` / `numerical_deploy`
9. `school_chale_hum_build` / `school_chale_hum_deploy`
10. `third_eye_build` / `third_eye_deploy`
11. `altered_datum_api_build` / `altered_datum_api_deploy`

## Quick Commands

### Run on New Server Setup

```bash
# 1. SSH into server
ssh arpansahu@192.168.1.200

# 2. Download scripts (option A: from repo)
cd /tmp
git clone https://github.com/arpansahu/common_readme.git
cd common_readme/post_server_setup
chmod +x *.sh
./create_jenkins_pipelines.sh

# 2. Download scripts (option B: copy from local)
# On local machine:
scp -r post_server_setup/ arpansahu@192.168.1.200:/tmp/
ssh arpansahu@192.168.1.200 "cd /tmp/post_server_setup && chmod +x *.sh && ./create_jenkins_pipelines.sh"
```

### Remote Execution (One-liner)

```bash
# From local machine - creates all pipelines automatically
scp -r post_server_setup/ arpansahu@192.168.1.200:/tmp/ && \
ssh arpansahu@192.168.1.200 "cd /tmp/post_server_setup && chmod +x *.sh && ./create_jenkins_pipelines.sh"
```

### Verify Created Jobs

```bash
# List all Jenkins jobs
ssh arpansahu@192.168.1.200 "java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth arpansahu:Gandu302@jenkins list-jobs"

# Get job details
ssh arpansahu@192.168.1.200 "java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth arpansahu:Gandu302@jenkins get-job common_readme"
```

### Trigger a Build

```bash
# Trigger common_readme pipeline
ssh arpansahu@192.168.1.200 'java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth arpansahu:Gandu302@jenkins build common_readme -p "project_git_url=" -p "environment=prod"'

# Trigger build pipeline
ssh arpansahu@192.168.1.200 'java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth arpansahu:Gandu302@jenkins build arpansahu_dot_me_build'

# Trigger deploy pipeline
ssh arpansahu@192.168.1.200 'java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth arpansahu:Gandu302@jenkins build arpansahu_dot_me_deploy -p "IMAGE_TAG=latest" -p "ENVIRONMENT=prod"'
```

## Access Jenkins UI

**URL:** https://jenkins.arpansahu.space

**Credentials:**
- Username: `arpansahu`
- Password: `Gandu302@jenkins`

## What Each Pipeline Does

### Build Pipelines (`*_build`)
- Checkout code from GitHub
- Run tests
- Build Docker image
- Push image to Harbor registry
- Tag image with commit SHA and branch name

### Deploy Pipelines (`*_deploy`)
- Pull Docker image from Harbor
- Stop existing container
- Start new container with updated image
- Run health checks
- Send email notification (success/failure)

### Common README Pipeline
- Updates README.md across all repositories
- Generates HTML documentation
- Updates GitHub wikis
- Commits and pushes changes

## Expected Jenkinsfiles in Repositories

Each Django application repository must have:
- `Jenkinsfile-build` - Build pipeline definition
- `Jenkinsfile-deploy` - Deploy pipeline definition

The common_readme repository has:
- `Jenkinsfile` - README management pipeline

## Troubleshooting

### Script fails with "connection refused"
```bash
# Check Jenkins is running
ssh arpansahu@192.168.1.200 "systemctl status jenkins"

# Restart if needed
ssh arpansahu@192.168.1.200 "sudo systemctl restart jenkins"
```

### Credentials not found error
Ensure in Jenkins UI:
1. Go to: Manage Jenkins → Credentials → System → Global credentials
2. Verify `github_auth` credential exists
3. Check it has your GitHub Personal Access Token

### Job already exists warning
This is normal! The script updates existing jobs instead of failing.

## Adding New Repositories

1. Edit `repos_config.sh`:
   ```bash
   ["my_new_repo"]="https://github.com/arpansahu/my_new_repo.git|true|true|django"
   ```

2. Re-run the script:
   ```bash
   ./create_jenkins_pipelines.sh
   ```

3. The script will create pipelines for the new repo and skip existing ones

## Script Features

✅ **Idempotent** - Safe to run multiple times  
✅ **Updates existing** - Won't duplicate jobs  
✅ **Colored output** - Easy to read progress  
✅ **Error handling** - Continues on individual failures  
✅ **Summary report** - Shows success/failure count  
✅ **Automatic ordering** - common_readme always first  

## Success Criteria

After running the script, you should see:
- ✅ 21 total jobs created
- ✅ All jobs listed in Jenkins UI
- ✅ SCM polling configured (every 5 minutes)
- ✅ No error messages in summary

## Next Steps After Pipeline Creation

1. **Verify in Jenkins UI**
   - Open https://jenkins.arpansahu.space
   - Check all 21 jobs are visible

2. **Test a Build**
   - Click on any `*_build` job
   - Click "Build Now"
   - Monitor console output

3. **Test a Deployment**
   - Click on any `*_deploy` job
   - Click "Build with Parameters"
   - Set IMAGE_TAG and ENVIRONMENT
   - Click "Build"

4. **Set up Webhooks (Optional)**
   - Go to each GitHub repository → Settings → Webhooks
   - Add: `https://jenkins.arpansahu.space/github-webhook/`
   - Select "Just the push event"
   - This replaces SCM polling with instant triggers

## Maintenance

### Update All Pipelines
```bash
# Re-run the script to update all job configurations
cd /tmp/post_server_setup
./create_jenkins_pipelines.sh
```

### Delete All Pipelines
```bash
# If you need to start fresh (BE CAREFUL!)
ssh arpansahu@192.168.1.200 'for job in $(java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth arpansahu:Gandu302@jenkins list-jobs); do java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth arpansahu:Gandu302@jenkins delete-job "$job"; done'
```

## Integration with Server Setup Checklist

Add to your new server setup process:

1. ✅ Install Ubuntu 22.04
2. ✅ Install Docker
3. ✅ Install Nginx + SSL
4. ✅ Install PostgreSQL
5. ✅ Install Redis
6. ✅ Install Harbor
7. ✅ Install Jenkins
8. ✅ Configure Jenkins credentials
9. ✅ **Run pipeline creation script** ← This step
10. ✅ Test deployments

## Time to Complete

- **Script execution:** ~30-60 seconds
- **Manual verification:** ~5 minutes
- **Total:** < 2 minutes (mostly automated)

## Support

If you encounter issues:
1. Check Jenkins is running: `systemctl status jenkins`
2. Verify credentials in Jenkins UI
3. Check GitHub token permissions (needs `repo` scope)
4. Review Jenkins logs: `/var/log/jenkins/jenkins.log`
5. Re-run script with debug: `bash -x create_jenkins_pipelines.sh`
