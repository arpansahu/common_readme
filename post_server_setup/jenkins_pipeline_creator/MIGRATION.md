# Migration Guide - Jenkins Pipeline Creator

## What Changed?

The Jenkins pipeline creation scripts have been reorganized into a separate directory with secure credential management.

### Before
```
post_server_setup/
├── create_jenkins_pipelines.sh    # Loaded creds from jenkins_project_env/.env.jenkins
├── generate_job_xml.sh
└── repos_config.sh
```

### After
```
post_server_setup/
├── jenkins_pipeline_creator/       # ✅ New organized directory
│   ├── .env.jenkins               # ✅ Own credential file (gitignored)
│   ├── .env.jenkins.example       # ✅ Template
│   ├── create_jenkins_pipelines.sh
│   ├── generate_job_xml.sh
│   ├── repos_config.sh
│   ├── README.md                  # ✅ Full documentation
│   └── QUICK_START.md             # ✅ Quick start guide
│
└── [old files still exist]        # ⚠️ Kept for reference, marked deprecated
```

## Why This Change?

### Problems Solved

1. **Security** ✅
   - Each tool has its own `.env.jenkins` file
   - No credentials in scripts or version control
   - Easy to manage different credentials per tool

2. **Organization** ✅
   - Pipeline creator has its own directory
   - Clear separation of concerns
   - Better documentation structure

3. **Maintainability** ✅
   - Each tool is self-contained
   - Independent credential management
   - Easier to understand and update

## Migration Steps

### If You're Using the Old Scripts

**Option 1: Start Fresh (Recommended)**

```bash
cd post_server_setup/jenkins_pipeline_creator

# Configure credentials
cp .env.jenkins.example .env.jenkins
nano .env.jenkins  # Add your Jenkins URL, username, API token

# Run the new script
./create_jenkins_pipelines.sh
```

**Option 2: Reuse Existing Credentials**

If you already have credentials in `jenkins_project_env/.env.jenkins`:

```bash
cd post_server_setup/jenkins_pipeline_creator

# Copy credentials from jenkins_project_env
cp ../jenkins_project_env/.env.jenkins .env.jenkins

# Run the script
./create_jenkins_pipelines.sh
```

### For Automated Workflows

**Before:**
```bash
cd post_server_setup
./create_jenkins_pipelines.sh
```

**After:**
```bash
cd post_server_setup/jenkins_pipeline_creator
./create_jenkins_pipelines.sh
```

### For Remote Execution

**Before:**
```bash
scp -r post_server_setup/ user@server:/tmp/
ssh user@server "cd /tmp/post_server_setup && ./create_jenkins_pipelines.sh"
```

**After:**
```bash
scp -r post_server_setup/jenkins_pipeline_creator/ user@server:/tmp/
ssh user@server "cd /tmp/jenkins_pipeline_creator && ./create_jenkins_pipelines.sh"
```

## What Stays the Same?

✅ **Script functionality** - Creates the same 21 pipelines  
✅ **Output format** - Same colored output and progress tracking  
✅ **Repository config** - `repos_config.sh` format unchanged  
✅ **XML generation** - Same `generate_job_xml.sh` functions  
✅ **Jenkins CLI** - Same `/tmp/jenkins-cli.jar` usage

## What's Different?

### 1. Credential Loading

**Before:**
```bash
ENV_FILE="${SCRIPT_DIR}/jenkins_project_env/.env.jenkins"
```

**After:**
```bash
ENV_FILE="${SCRIPT_DIR}/.env.jenkins"
```

### 2. Error Messages

**Before:**
```
ERROR: Jenkins credentials file not found: jenkins_project_env/.env.jenkins
```

**After:**
```
ERROR: Jenkins credentials file not found: .env.jenkins
Please create .env.jenkins with Jenkins API credentials
Copy .env.jenkins.example to .env.jenkins and fill in your credentials
```

### 3. Directory Structure

Each tool is now self-contained with its own:
- Credentials (`.env.jenkins`)
- Documentation (`README.md`, `QUICK_START.md`)
- Scripts (all related files in one directory)

## Breaking Changes

### ⚠️ Path Changes

If you have scripts or documentation that reference the old paths, update them:

```bash
# Old paths (deprecated)
post_server_setup/create_jenkins_pipelines.sh
post_server_setup/generate_job_xml.sh
post_server_setup/repos_config.sh

# New paths
post_server_setup/jenkins_pipeline_creator/create_jenkins_pipelines.sh
post_server_setup/jenkins_pipeline_creator/generate_job_xml.sh
post_server_setup/jenkins_pipeline_creator/repos_config.sh
```

### ⚠️ Credential File Location

**Old:** Shared credentials from `jenkins_project_env/.env.jenkins`  
**New:** Separate credentials in `jenkins_pipeline_creator/.env.jenkins`

You'll need to create/copy the `.env.jenkins` file in the new location.

## Backward Compatibility

### Old Scripts Still Work

The old scripts in `post_server_setup/` root are **kept for backward compatibility** but marked as **deprecated**.

- ✅ They still function
- ⚠️ They use old credential loading (from `jenkins_project_env/`)
- ⚠️ They're not documented in main README
- ❌ They won't receive updates

**Recommendation:** Migrate to `jenkins_pipeline_creator/` for:
- Better security
- Active maintenance
- Full documentation
- Independent credential management

## Testing Your Migration

### 1. Syntax Check
```bash
cd jenkins_pipeline_creator
bash -n create_jenkins_pipelines.sh
# Should output nothing (no errors)
```

### 2. Credential Check
```bash
cd jenkins_pipeline_creator
cat .env.jenkins
# Should show: JENKINS_URL, JENKINS_USER, JENKINS_API_TOKEN, JENKINS_CLI
```

### 3. Dry Run (Check Connection)
```bash
cd jenkins_pipeline_creator
./create_jenkins_pipelines.sh
# Should show: "✓ Jenkins credentials loaded from .env.jenkins"
# Should connect to Jenkins and list existing jobs
# Press Ctrl+C after verification (or let it complete)
```

### 4. Full Run
```bash
cd jenkins_pipeline_creator
./create_jenkins_pipelines.sh
# Should create/update all 21 pipelines
```

## Rollback Plan

If something goes wrong, you can still use the old scripts:

```bash
# Go back to old location
cd post_server_setup

# Use old scripts (they still exist)
./create_jenkins_pipelines.sh
```

But note: The old scripts load credentials from `jenkins_project_env/.env.jenkins`.

## FAQ

### Q: Do I need to delete the old scripts?

**A:** No, they're kept for reference and backward compatibility. The README clearly marks them as deprecated.

### Q: Will the old scripts be updated?

**A:** No, all updates will go to `jenkins_pipeline_creator/`. The old scripts are frozen for backward compatibility only.

### Q: Can I use different credentials for pipeline creation vs env upload?

**A:** Yes! Each directory has its own `.env.jenkins`:
- `jenkins_pipeline_creator/.env.jenkins` - For creating pipelines
- `jenkins_project_env/.env.jenkins` - For uploading env variables

They can have different Jenkins credentials if needed.

### Q: What if I already ran the old script?

**A:** No problem! The new script is idempotent:
- Existing pipelines will be updated (not duplicated)
- New pipelines will be created
- No data loss

Just run the new script and it will work correctly.

### Q: Do I need to reconfigure my pipelines in Jenkins?

**A:** No, the pipelines themselves are unchanged. Only the creation script moved to a new directory.

## Complete Migration Checklist

- [ ] 1. Navigate to new directory: `cd jenkins_pipeline_creator`
- [ ] 2. Copy credential template: `cp .env.jenkins.example .env.jenkins`
- [ ] 3. Add your credentials to `.env.jenkins`
- [ ] 4. Verify syntax: `bash -n create_jenkins_pipelines.sh`
- [ ] 5. Test connection by running script (Ctrl+C to abort)
- [ ] 6. Full run: `./create_jenkins_pipelines.sh`
- [ ] 7. Verify in Jenkins UI: All 21 pipelines exist
- [ ] 8. Update any scripts/docs that reference old paths
- [ ] 9. Inform team members of new directory structure
- [ ] 10. Update CI/CD workflows if they use old paths

## Support

For issues or questions:

1. Check [jenkins_pipeline_creator/README.md](README.md) for detailed docs
2. Check [jenkins_pipeline_creator/QUICK_START.md](QUICK_START.md) for quick reference
3. See [Troubleshooting section](README.md#troubleshooting) in README
4. Compare your setup with the working examples

## Summary

✅ **Use:** `post_server_setup/jenkins_pipeline_creator/`  
⚠️ **Deprecated:** `post_server_setup/*.sh` (old scripts)  
🔒 **Security:** Each tool has own `.env.jenkins` (gitignored)  
📚 **Docs:** Full README and QUICK_START in each directory

**Migration is simple:** Copy `.env.jenkins` and use new directory! 🚀
