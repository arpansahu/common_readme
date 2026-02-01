# Quick Start Guide

## 🚀 Upload Project .env to Jenkins

### Step 1: Navigate to directory
```bash
cd post_server_setup/jenkins_project_env
```

### Step 2: Run the upload script
```bash
./upload_project_env.sh
```

### Step 3: Follow the prompts

**Prompt 1: Enter Project Name**
```
Project name: arpansahu_dot_me
```

**Prompt 2: Paste .env Content**
```
# Paste your entire .env file here
SECRET_KEY=your_secret_key
DEBUG=0
DATABASE_URL=postgresql://...
# ... (paste all variables)

# Press Ctrl+D when done
```

**Prompt 3: Confirm Upload**
```
Upload this to Jenkins as 'arpansahu_dot_me_env_file'? (y/n): y
```

### Step 4: Verify
Visit: https://jenkins.arpansahu.space/credentials/

You should see: `arpansahu_dot_me_env_file`

---

## 📝 Example: Upload from file

If you have a file ready:

```bash
./upload_project_env.sh << 'EOF'
arpansahu_dot_me
SECRET_KEY='#9+_!5*2(8&6$4z0^v7)b1%n3@m=k-l?p:q;r.x,j/w'
DEBUG=0
DATABASE_URL=postgresql://postgres:Gandu302postgres@arpansahu.space:5432/arpansahu?options=-c%20search_path=arpansahu_dot_me
REDIS_URL=redis://:Gandu302redis@arpansahu.space:6379/0
# ... all other variables
EOF
```

Or from a file:
```bash
cat << EOF | ./upload_project_env.sh
arpansahu_dot_me
$(cat /path/to/your/.env)
EOF
```

---

## 🔄 Update Existing Credential

Just run the script again with the same project name. It will automatically update the existing credential.

---

## ✅ All Done!

Now use it in your Jenkinsfile:
```groovy
withCredentials([file(credentialsId: 'arpansahu_dot_me_env_file', variable: 'ENV_FILE')]) {
    sh 'cp $ENV_FILE .env'
}
```
