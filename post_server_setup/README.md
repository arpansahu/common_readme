# Jenkins Pipeline Creator - Simplified

Three simple scripts to manage Jenkins pipelines and environment variables.

## Prerequisites

1. Jenkins API credentials configured in `.env.jenkins`:
```bash
cp .env.jenkins.example .env.jenkins
# Edit .env.jenkins with your credentials
```

2. Jenkins CLI jar downloaded (automatic on first run)

## Scripts

### 1️⃣ Create All Pipelines

**Purpose**: Creates Jenkins pipeline jobs for all projects in `repos_config.sh`

```bash
./1_create_all_pipelines.sh
```

**Features**:
- Reads project list from `repos_config.sh`
- Creates build and deploy jobs automatically
- Skips existing jobs
- Shows summary of created/skipped/failed jobs

**Output**:
```
✓ Created django_starter_build
✓ Created django_starter_deploy
⊘ borcelle_crm_build already exists (skipped)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Created: 15
⊘ Skipped: 5
✗ Failed:  0
```

---

### 2️⃣ Upload Environment (Interactive)

**Purpose**: Upload/update Jenkins credentials interactively

```bash
./2_upload_env_interactive.sh
```

**Usage**:
1. Run the script
2. Enter credential ID (e.g., `django_starter_env`)
3. Enter description (optional)
4. Paste your `.env` content
5. Press `Ctrl+D` to finish
6. Confirm upload

**Example**:
```bash
$ ./2_upload_env_interactive.sh
Enter credential ID: django_starter_env
Enter description: Django Starter Environment Variables
Paste your .env content (press Ctrl+D when done):
DEBUG=True
SECRET_KEY=xxx
DATABASE_URL=postgresql://...
^D

Preview:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Credential ID: django_starter_env
Description: Django Starter Environment Variables
Content lines: 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Upload this credential? (y/n): y
✓ Successfully created credential: django_starter_env
```

---

### 3️⃣ Upload Environment (Automated)

**Purpose**: Upload/update Jenkins credentials non-interactively (for scripts/CI)

```bash
./3_upload_env_automated.sh <credential_id> <env_file_path> [description]
```

**Arguments**:
- `credential_id`: Jenkins credential ID (e.g., `django_starter_env`)
- `env_file_path`: Path to .env file
- `description`: (Optional) Description of the credential

**Examples**:

Upload new credential:
```bash
./3_upload_env_automated.sh django_starter_env /path/to/.env
```

With custom description:
```bash
./3_upload_env_automated.sh \
  borcelle_env \
  ~/projects/borcelle_crm/.env \
  "Borcelle CRM Production Environment"
```

Update existing credential:
```bash
./3_upload_env_automated.sh django_starter_env /path/to/.env.updated
```

**Output**:
```
✓ Connected to Jenkins

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Credential ID: django_starter_env
Source file: /path/to/.env
Description: Environment variables for django_starter_env
Content lines: 15
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Creating new credential...
✓ Successfully created credential: django_starter_env

✓ Operation completed successfully
```

---

## Use Cases

### Initial Setup
```bash
# 1. Create all pipelines
./1_create_all_pipelines.sh

# 2. Upload environment for each project
./3_upload_env_automated.sh django_starter_env ~/projects/django_starter/.env
./3_upload_env_automated.sh borcelle_env ~/projects/borcelle_crm/.env
```

### Update Environment Variable
```bash
# Interactive (paste content)
./2_upload_env_interactive.sh

# Automated (from file)
./3_upload_env_automated.sh django_starter_env /path/to/.env.updated
```

### CI/CD Integration
```bash
# In your deployment script
./3_upload_env_automated.sh "$PROJECT_NAME_env" "$ENV_FILE" "$DESCRIPTION"
```

### AI Agent Usage
```bash
# Agent can use script 3 to update env without human intervention
./3_upload_env_automated.sh project_env /tmp/generated.env "Auto-updated by agent"
```

---

## Configuration

### repos_config.sh
Define your projects:
```bash
REPOS_LIST="
project_name|git_url|has_build|has_deploy|type
django_starter|https://github.com/user/django_starter.git|true|true|django
"
```

### .env.jenkins
Jenkins API credentials:
```bash
JENKINS_URL=https://jenkins.example.com
JENKINS_USER=your_username
JENKINS_API_TOKEN=your_api_token
```

---

## Troubleshooting

**Connection failed**:
- Verify `.env.jenkins` credentials
- Check Jenkins URL is accessible
- Ensure API token is valid

**Credential upload failed**:
- Verify Jenkins has "Credentials" plugin installed
- Check user has permission to manage credentials
- Ensure credential ID doesn't contain special characters

**Pipeline creation failed**:
- Verify GitHub credentials exist in Jenkins (ID: `github_auth`)
- Check user has permission to create jobs
- Ensure Jenkins has required plugins (Git, Pipeline)

---

## Old Scripts

The original scripts still exist for advanced use:
- `create_jenkins_pipelines.sh` - Full featured pipeline creator
- `generate_job_xml.sh` - XML generation functions
- `README.md` - Detailed documentation
- `QUICK_START.md` - Quick start guide

These new scripts are simpler and cover 99% of use cases.
