# Jenkins Project Environment Management

Simplified approach: Store entire `.env` file as a single Jenkins credential per project.

## Prerequisites

### macOS/Linux

**Java 21 is required** to run Jenkins CLI.

**Install on macOS:**
```bash
brew install openjdk@21
echo 'export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
java -version  # Verify installation
```

**Install on Linux:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y openjdk-21-jre

# Verify
java -version
```

**Or use the automated setup script:**
```bash
cd post_server_setup/jenkins_project_env
./setup_prerequisites.sh
```

## Setup

1. **Configure Jenkins credentials** (one-time setup):
   ```bash
   cp .env.jenkins.example .env.jenkins
   nano .env.jenkins  # Add your Jenkins credentials
   ```

2. **Upload project .env file**:
   ```bash
   ./upload_project_env.sh
   ```
   
   The script will:
   - Ask for project name (e.g., `arpansahu_dot_me`)
   - Prompt you to paste your `.env` file content
   - Upload to Jenkins as `{project_name}_env_file`

## Usage in Jenkinsfile

```groovy
stage('Setup Environment') {
    steps {
        withCredentials([
            file(credentialsId: 'arpansahu_dot_me_env_file', variable: 'ENV_FILE')
        ]) {
            sh 'cp $ENV_FILE .env'
        }
    }
}
```

## Files

- `.env.jenkins` - Jenkins API credentials (not in git)
- `.env.jenkins.example` - Template for Jenkins credentials
- `upload_project_env.sh` - Interactive script to upload .env files

## Example Workflow

```bash
# 1. Prepare your .env file locally
cat > /tmp/my_project.env << 'EOF'
SECRET_KEY=your_secret_key
DEBUG=0
DATABASE_URL=postgresql://...
# ... all your variables
EOF

# 2. Upload to Jenkins
./upload_project_env.sh
# Enter project name: my_project
# Paste .env content (or redirect: < /tmp/my_project.env)
# Ctrl+D to finish

# 3. Use in Jenkinsfile
# withCredentials([file(credentialsId: 'my_project_env_file', variable: 'ENV_FILE')])
```

## Benefits

✅ **Simple**: One credential per project  
✅ **Secure**: Encrypted in Jenkins  
✅ **Easy to update**: Just run the script again  
✅ **Version control**: Keep configs in git (without secrets)  
✅ **No sudo needed**: Jenkins handles everything
