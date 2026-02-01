## Jenkins (CI/CD Automation Server)

Jenkins is an open-source automation server that enables developers to build, test, and deploy applications through continuous integration and continuous delivery (CI/CD). This guide provides a complete, production-ready setup with Java 21, Jenkins LTS, Nginx reverse proxy, and comprehensive credential management.

### Prerequisites

Before installing Jenkins, ensure you have:

1. Ubuntu Server 22.04 LTS
2. Nginx with SSL certificates configured
3. Domain name (example: jenkins.arpansahu.space)
4. Wildcard SSL certificate already issued (via acme.sh)
5. Minimum 2GB RAM, 20GB disk space
6. Root or sudo access
7. Docker installed (for containerized builds)

### Architecture Overview

```
Internet (HTTPS)
   │
   └─ Nginx (Port 443) - TLS Termination
        │
        └─ jenkins.arpansahu.space
             │
             └─ Jenkins (localhost:8080)
                  │
                  ├─ Jenkins Controller (Web UI + API)
                  ├─ Build Agents (local/remote)
                  ├─ Workspace (/var/lib/jenkins)
                  └─ Credentials Store
```

Key Principles:
- Jenkins runs on localhost only (port 8080)
- Nginx handles all TLS termination
- Credentials stored in Jenkins encrypted store
- Pipelines defined as code (Jenkinsfile)
- Docker-based builds for isolation

### Why Jenkins

**Advantages:**
- Open-source and free
- Extensive plugin ecosystem (1800+)
- Pipeline as Code (Jenkinsfile)
- Distributed builds
- Docker integration
- GitHub/GitLab integration
- Email notifications
- Role-based access control

**Use Cases:**
- Automated builds on commit
- Automated testing
- Docker image building
- Deployment automation
- Scheduled jobs
- Integration with Harbor registry
- Multi-branch pipelines

### Part 1: Install Java 21

Jenkins requires Java to run. We'll install OpenJDK 21 (latest LTS).

**⚠️ Important:** Java 17 support ends March 31, 2026. Use Java 21 for continued support.

#### Check Current Java Version

```bash
java -version
```

If you see Java 17 or older, follow the upgrade steps below.

#### Upgrade from Java 17 to Java 21 (If Needed)

If Jenkins is already installed on Java 17:

1. Install Java 21

    ```bash
    sudo apt update
    sudo apt install -y openjdk-21-jdk
    ```

2. Check Jenkins service status

    ```bash
    sudo systemctl status jenkins
    ```

3. Update Jenkins to use Java 21

    ```bash
    sudo systemctl stop jenkins
    sudo update-alternatives --config java
    ```

    Select Java 21 from the list (e.g., `/usr/lib/jvm/java-21-openjdk-amd64/bin/java`)

4. Verify Java version

    ```bash
    java -version
    ```

    Should show: `openjdk version "21.0.x"`

5. Update JAVA_HOME for Jenkins

    ```bash
    sudo nano /etc/default/jenkins
    ```

    Add or update:
    ```bash
    JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
    JENKINS_JAVA_CMD="$JAVA_HOME/bin/java"
    ```

6. Restart Jenkins

    ```bash
    sudo systemctl start jenkins
    sudo systemctl status jenkins
    ```

7. Verify in Jenkins UI

    Dashboard → Manage Jenkins → System Information → Look for `java.version` (should be 21.x)

#### Fresh Installation of Java 21

For new installations:

1. Update system packages

    ```bash
    sudo apt update
    ```

2. Install OpenJDK 21

    ```bash
    sudo apt install -y openjdk-21-jdk
    ```

3. Verify Java installation

    ```bash
    java -version
    ```

    Expected output:
    ```
    openjdk version "21.0.x" 2024-xx-xx
    OpenJDK Runtime Environment (build 21.0.x+x)
    OpenJDK 64-Bit Server VM (build 21.0.x+x, mixed mode, sharing)
    ```

4. Set JAVA_HOME (optional but recommended)

    ```bash
    sudo nano /etc/environment
    ```

    Add:
    ```bash
    JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
    ```

    Apply changes:
    ```bash
    source /etc/environment
    echo $JAVA_HOME
    ```

### Part 2: Install Jenkins LTS

Jenkins Long-Term Support (LTS) releases are recommended for production environments. Current LTS: **2.528.3**

1. Add Jenkins repository key (both legacy and modern format for compatibility)

    ```bash
    # Modern keyring format (recommended)
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo gpg --dearmor -o /usr/share/keyrings/jenkins-archive-keyring.gpg
    
    # Also add legacy key for repository compatibility
    gpg --keyserver keyserver.ubuntu.com --recv-keys 7198F4B714ABFC68
    gpg --export 7198F4B714ABFC68 > /tmp/jenkins-key.gpg
    sudo gpg --dearmor < /tmp/jenkins-key.gpg > /usr/share/keyrings/jenkins-old-keyring.gpg
    ```

2. Add Jenkins repository

    ```bash
    echo "deb [signed-by=/usr/share/keyrings/jenkins-old-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    ```

3. Update package list

    ```bash
    sudo apt update
    ```

4. Install Jenkins (latest LTS)

    ```bash
    # Install latest LTS version
    sudo apt install -y jenkins
    
    # Or install specific LTS version
    # sudo apt install -y jenkins=2.528.3
    ```

5. Check installed version

    ```bash
    jenkins --version
    ```

    Expected: `2.528.3` or newer LTS

6. Enable Jenkins service

    ```bash
    sudo systemctl enable jenkins
    ```

7. Start Jenkins service

    ```bash
    sudo systemctl start jenkins
    ```

8. Verify Jenkins is running

    ```bash
    sudo systemctl status jenkins
    ```

    Expected: Active (running)

9. Check Jenkins is listening on port 8080

    ```bash
    sudo ss -tulnp | grep 8080
    ```

    Expected: Jenkins listening on 127.0.0.1:8080

### Part 2.1: Upgrade Jenkins to Latest LTS

To upgrade an existing Jenkins installation:

1. Check current version

    ```bash
    jenkins --version
    # Or via API:
    curl -s -I https://jenkins.arpansahu.space/api/json | grep X-Jenkins
    ```

2. Check available versions

    ```bash
    apt-cache policy jenkins | head -30
    ```

    Note: Look for versions 2.xxx.x (LTS releases), not 2.5xx+ (weekly releases)

3. Backup Jenkins before upgrade

    ```bash
    sudo tar -czf /tmp/jenkins-backup-$(date +%Y%m%d-%H%M%S).tar.gz /var/lib/jenkins/
    ```

4. Stop Jenkins

    ```bash
    sudo systemctl stop jenkins
    ```

5. Upgrade to latest LTS

    ```bash
    sudo apt update
    sudo apt install --only-upgrade jenkins -y
    
    # Or install specific LTS version:
    # sudo apt install jenkins=2.528.3 -y
    ```

6. Start Jenkins

    ```bash
    sudo systemctl start jenkins
    ```

7. Verify upgrade

    ```bash
    jenkins --version
    sudo systemctl status jenkins
    ```

8. Check Jenkins UI

    https://jenkins.arpansahu.space → Manage Jenkins → About Jenkins

### Part 3: Configure Nginx Reverse Proxy

1. Edit Nginx configuration

    ```bash
    sudo nano /etc/nginx/sites-available/services
    ```

2. Add Jenkins server block

    ```nginx
    # Jenkins CI/CD - HTTP → HTTPS
    server {
        listen 80;
        listen [::]:80;
        server_name jenkins.arpansahu.space;
        return 301 https://$host$request_uri;
    }

    # Jenkins CI/CD - HTTPS
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name jenkins.arpansahu.space;

        ssl_certificate     /etc/nginx/ssl/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;

        # Jenkins-specific timeouts
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;

        location / {
            proxy_pass http://127.0.0.1:8080;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;

            # Required for Jenkins CLI and agent connections
            proxy_http_version 1.1;
            proxy_request_buffering off;
        }
    }
    ```

3. Test Nginx configuration

    ```bash
    sudo nginx -t
    ```

4. Reload Nginx

    ```bash
    sudo systemctl reload nginx
    ```

### Part 4: Initial Jenkins Setup

1. Get initial admin password

    ```bash
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
    ```

    Copy this password (example: a1b2c3d4e5f6...)

2. Access Jenkins Web UI

    Go to: https://jenkins.arpansahu.space

3. Enter initial admin password

    Paste the password from step 1.

4. Install suggested plugins

    - Click: Install suggested plugins
    - Wait for plugin installation (5-10 minutes)

5. Create admin user

    Configure:
    - Username: `admin`
    - Password: (your strong password)
    - Full name: `Admin User`
    - Email: your-email@example.com

    Click: Save and Continue

6. Configure Jenkins URL

    Jenkins URL: `https://jenkins.arpansahu.space`

    Click: Save and Finish

7. Start using Jenkins

    Click: Start using Jenkins

### Part 5: Configure Jenkins Credentials

Jenkins stores credentials securely for use in pipelines. We'll configure 4 essential credentials.

#### 5.1: GitHub Authentication Credentials

1. Navigate to credentials

    Dashboard → Manage Jenkins → Credentials → System → Global credentials → Add Credentials

2. Configure GitHub credentials

    - **Kind**: Username with password
    - **Scope**: Global
    - **Username**: `arpansahu` (your GitHub username)
    - **Password**: `ghp_xxxxxxxxxxxx` (GitHub Personal Access Token)
    - **ID**: `github-auth`
    - **Description**: `Github Auth`

    Click: Create

    Note: Generate GitHub PAT at https://github.com/settings/tokens with scopes: repo, admin:repo_hook

#### 5.2: Harbor Registry Credentials

1. Add Harbor credentials

    Dashboard → Manage Jenkins → Credentials → System → Global credentials → Add Credentials

2. Configure Harbor credentials

    - **Kind**: Username with password
    - **Scope**: Global
    - **Username**: `admin` (or robot account: `robot$ci-bot`)
    - **Password**: (Harbor password or robot token)
    - **ID**: `harbor-credentials`
    - **Description**: `harbor-credentials`

    Click: Create

#### 5.3: Jenkins Admin API Credentials

1. Add Jenkins admin credentials

    Dashboard → Manage Jenkins → Credentials → System → Global credentials → Add Credentials

2. Configure Jenkins API credentials

    - **Kind**: Username with password
    - **Scope**: Global
    - **Username**: `admin` (Jenkins admin username)
    - **Password**: (Jenkins admin password)
    - **ID**: `jenkins-admin-credentials`
    - **Description**: `Jenkins admin credentials for API authentication and pipeline usage`

    Click: Create

    Use case: Pipeline triggers, REST API calls, remote job execution

#### 5.4: Sentry Authentication Token

1. Add Sentry CLI token

    Dashboard → Manage Jenkins → Credentials → System → Global credentials → Add Credentials

2. Configure Sentry credentials

    - **Kind**: Secret text
    - **Scope**: Global
    - **Secret**: (Sentry auth token from https://sentry.io/settings/account/api/auth-tokens/)
    - **ID**: `sentry-auth-token`
    - **Description**: `Sentry CLI Authentication Token`

    Click: Create

    Use case: Sentry release tracking, source map uploads, error monitoring integration

#### 5.5: GitHub Authentication Credentials

1. Add GitHub credentials

    Dashboard → Manage Jenkins → Credentials → System → Global credentials → Add Credentials

2. Configure GitHub credentials

    - **Kind**: Username with password
    - **Scope**: Global
    - **Username**: (GitHub username)
    - **Password**: (GitHub Personal Access Token with repo permissions)
    - **ID**: `github_auth`
    - **Description**: `GitHub authentication for branch merging and repository operations`

    Click: Create

    **How to generate GitHub PAT:**
    1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
    2. Generate new token with permissions: `repo` (Full control of private repositories)
    3. Copy token immediately (shown only once)

    Use case: Automated branch merging, repository operations, deployment workflows

### Part 6: Configure Global Jenkins Variables

Global variables are available to all Jenkins pipelines.

1. Navigate to system configuration

    Dashboard → Manage Jenkins → System

2. Scroll to Global properties

    Check: Environment variables

3. Add global variables

    Click: Add (for each variable)

    | Name | Value | Description |
    | ---- | ----- | ----------- |
    | MAIL_JET_API_KEY | (your Mailjet API key) | Email notification service |
    | MAIL_JET_API_SECRET | (your Mailjet secret) | Email notification service |
    | MAIL_JET_EMAIL_ADDRESS | noreply@arpansahu.space | Sender email address |
    | MY_EMAIL_ADDRESS | your-email@example.com | Notification recipient |

4. Save configuration

    Scroll down and click: Save

### Part 7: Configure Jenkins for Docker Builds

Jenkins needs Docker access to build containerized applications.

1. Add Jenkins user to Docker group

    ```bash
    sudo usermod -aG docker jenkins
    ```

2. Restart Jenkins to apply group changes

    ```bash
    sudo systemctl restart jenkins
    ```

3. Verify Jenkins can access Docker

    ```bash
    sudo -u jenkins docker ps
    ```

    Expected: Docker container list (even if empty)

### Part 8: Configure Jenkins Sudo Access (Optional)

Required if pipelines need to copy files from protected directories.

1. Edit sudoers file

    ```bash
    sudo visudo
    ```

2. Add Jenkins sudo permissions

    Add at end of file:
    ```bash
    # Allow Jenkins to run specific commands without password
    jenkins ALL=(ALL) NOPASSWD: /bin/cp, /bin/mkdir, /bin/chown
    ```

    Or for full sudo access (less secure):
    ```bash
    jenkins ALL=(ALL) NOPASSWD: ALL
    ```

3. Save and exit

    In nano: `Ctrl + O`, `Enter`, `Ctrl + X`
    In vi: `Esc`, `:wq`, `Enter`

4. Verify sudo access

    ```bash
    sudo -u jenkins sudo -l
    ```

### Part 9: Create Project Nginx Configuration

Each project needs its own Nginx configuration for deployment.

1. Create project Nginx configuration

    ```bash
    sudo nano /etc/nginx/sites-available/my-django-app
    ```

2. Add project server block (Docker deployment)

    ```nginx
    # Django App - HTTP → HTTPS
    server {
        listen 80;
        listen [::]:80;
        server_name myapp.arpansahu.space;
        return 301 https://$host$request_uri;
    }

    # Django App - HTTPS
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name myapp.arpansahu.space;

        ssl_certificate     /etc/nginx/ssl/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;

        location / {
            proxy_pass http://127.0.0.1:8000;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;

            # WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
    ```

3. For Kubernetes deployment (alternative)

    Replace `proxy_pass` line:
    ```nginx
    proxy_pass http://<CLUSTER_IP>:30080;
    ```

4. Enable site configuration

    ```bash
    sudo ln -s /etc/nginx/sites-available/my-django-app /etc/nginx/sites-enabled/
    ```

5. Test Nginx configuration

    ```bash
    sudo nginx -t
    ```

6. Reload Nginx

    ```bash
    sudo systemctl reload nginx
    ```

### Part 10: Create Jenkinsfile for Build Pipeline

Create `Jenkinsfile-build` in your project repository root.

Example Jenkinsfile-build:

```groovy
pipeline {
    agent { label 'local' }
    
    environment {
        HARBOR_URL = 'harbor.arpansahu.space'
        HARBOR_PROJECT = 'library'
        IMAGE_NAME = 'my-django-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}")
                }
            }
        }
        
        stage('Push to Harbor') {
            steps {
                script {
                    docker.withRegistry("https://${HARBOR_URL}", 'harbor-credentials') {
                        docker.image("${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}").push()
                        docker.image("${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}").push('latest')
                    }
                }
            }
        }
        
        stage('Trigger Deploy') {
            steps {
                build job: 'my-django-app-deploy', wait: false
            }
        }
    }
    
    post {
        success {
            emailext(
                subject: "Build Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Build completed successfully.",
                to: "${env.MY_EMAIL_ADDRESS}"
            )
        }
        failure {
            emailext(
                subject: "Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Build failed. Check Jenkins console output.",
                to: "${env.MY_EMAIL_ADDRESS}"
            )
        }
    }
}
```

### Part 11: Create Jenkinsfile for Deploy Pipeline

Create `Jenkinsfile-deploy` in your project repository root.

Example Jenkinsfile-deploy:

```groovy
pipeline {
    agent { label 'local' }
    
    environment {
        HARBOR_URL = 'harbor.arpansahu.space'
        HARBOR_PROJECT = 'library'
        IMAGE_NAME = 'my-django-app'
        CONTAINER_NAME = 'my-django-app'
        CONTAINER_PORT = '8000'
    }
    
    stages {
        stage('Stop Old Container') {
            steps {
                script {
                    sh """
                        docker stop ${CONTAINER_NAME} || true
                        docker rm ${CONTAINER_NAME} || true
                    """
                }
            }
        }
        
        stage('Pull Latest Image') {
            steps {
                script {
                    docker.withRegistry("https://${HARBOR_URL}", 'harbor-credentials') {
                        docker.image("${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:latest").pull()
                    }
                }
            }
        }
        
        stage('Deploy Container') {
            steps {
                script {
                    sh """
                        docker run -d \
                          --name ${CONTAINER_NAME} \
                          --restart unless-stopped \
                          -p ${CONTAINER_PORT}:8000 \
                          --env-file /var/lib/jenkins/.env/${IMAGE_NAME} \
                          ${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}:latest
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    sleep(time: 10, unit: 'SECONDS')
                    sh "curl -f http://localhost:${CONTAINER_PORT}/health || exit 1"
                }
            }
        }
    }
    
    post {
        success {
            emailext(
                subject: "Deploy Success: ${env.JOB_NAME}",
                body: "Deployment completed successfully.",
                to: "${env.MY_EMAIL_ADDRESS}"
            )
        }
        failure {
            emailext(
                subject: "Deploy Failed: ${env.JOB_NAME}",
                body: "Deployment failed. Check Jenkins console output.",
                to: "${env.MY_EMAIL_ADDRESS}"
            )
        }
    }
}
```

### Part 12: Create Jenkins Pipeline Projects

#### 12.1: Create Build Pipeline

1. Create new pipeline

    Dashboard → New Item

2. Configure pipeline

    - **Name**: `my-django-app-build`
    - **Type**: Pipeline
    - Click: OK

3. Configure pipeline settings

    - **Description**: Build and push Docker image to Harbor
    - **GitHub project**: (check and add your repo URL)
    - **Build Triggers**: GitHub hook trigger for GITScm polling

4. Configure Pipeline definition

    - **Definition**: Pipeline script from SCM
    - **SCM**: Git
    - **Repository URL**: `https://github.com/arpansahu/my-django-app.git`
    - **Credentials**: `github-auth`
    - **Branch**: `*/build`
    - **Script Path**: `Jenkinsfile-build`

5. Save pipeline

    Click: Save

#### 12.2: Create Deploy Pipeline

1. Create new pipeline

    Dashboard → New Item

2. Configure pipeline

    - **Name**: `my-django-app-deploy`
    - **Type**: Pipeline
    - Click: OK

3. Configure pipeline settings

    - **Description**: Deploy Docker container from Harbor
    - **Build Triggers**: None (triggered by build pipeline)

4. Configure Pipeline definition

    - **Definition**: Pipeline script from SCM
    - **SCM**: Git
    - **Repository URL**: `https://github.com/arpansahu/my-django-app.git`
    - **Credentials**: `github-auth`
    - **Branch**: `*/main`
    - **Script Path**: `Jenkinsfile-deploy`

5. Save pipeline

    Click: Save

### Part 13: Configure Environment Files

Store sensitive environment variables outside the repository.

1. Create environment file directory

    ```bash
    sudo mkdir -p /var/lib/jenkins/.env
    sudo chown jenkins:jenkins /var/lib/jenkins/.env
    ```

2. Create project environment file

    ```bash
    sudo nano /var/lib/jenkins/.env/my-django-app
    ```

3. Add environment variables

    ```bash
    # Django settings
    SECRET_KEY=your-secret-key-here
    DEBUG=False
    ALLOWED_HOSTS=myapp.arpansahu.space

    # Database
    DATABASE_URL=postgresql://user:pass@db:5432/myapp

    # Redis
    REDIS_URL=redis://redis:6379/0

    # Email
    EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
    EMAIL_HOST=smtp.mailjet.com
    EMAIL_PORT=587
    EMAIL_USE_TLS=True
    EMAIL_HOST_USER=your-mailjet-api-key
    EMAIL_HOST_PASSWORD=your-mailjet-secret

    # Sentry
    SENTRY_DSN=https://xxx@sentry.io/xxx
    ```

4. Set proper permissions

    ```bash
    sudo chown jenkins:jenkins /var/lib/jenkins/.env/my-django-app
    sudo chmod 600 /var/lib/jenkins/.env/my-django-app
    ```

### Part 14: Configure Email Notifications

1. Install Email Extension Plugin

    Dashboard → Manage Jenkins → Plugins → Available plugins
    
    Search: `Email Extension Plugin`
    
    Click: Install

2. Configure SMTP settings

    Dashboard → Manage Jenkins → System → Extended E-mail Notification

    Configure:
    - **SMTP server**: `in-v3.mailjet.com`
    - **SMTP port**: `587`
    - **Use SMTP Authentication**: ✓ Checked
    - **User Name**: `${MAIL_JET_API_KEY}`
    - **Password**: `${MAIL_JET_API_SECRET}`
    - **Use TLS**: ✓ Checked
    - **Default user e-mail suffix**: `@arpansahu.space`

3. Test email configuration

    Click: Test configuration by sending test e-mail

    Enter: `${MY_EMAIL_ADDRESS}`

    Expected: Email received

4. Save configuration

    Click: Save

### Managing Jenkins Service

1. Check Jenkins status

    ```bash
    sudo systemctl status jenkins
    ```

2. Stop Jenkins

    ```bash
    sudo systemctl stop jenkins
    ```

3. Start Jenkins

    ```bash
    sudo systemctl start jenkins
    ```

4. Restart Jenkins

    ```bash
    sudo systemctl restart jenkins
    ```

5. View Jenkins logs

    ```bash
    sudo journalctl -u jenkins -f
    ```

6. View Jenkins application logs

    ```bash
    sudo tail -f /var/log/jenkins/jenkins.log
    ```

### Backup and Restore

1. Backup Jenkins home directory

    ```bash
    # Stop Jenkins
    sudo systemctl stop jenkins

    # Backup Jenkins home
    sudo tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz /var/lib/jenkins

    # Start Jenkins
    sudo systemctl start jenkins
    ```

2. Backup only critical data

    ```bash
    sudo tar -czf jenkins-config-backup-$(date +%Y%m%d).tar.gz \
      /var/lib/jenkins/config.xml \
      /var/lib/jenkins/jobs/ \
      /var/lib/jenkins/users/ \
      /var/lib/jenkins/credentials.xml \
      /var/lib/jenkins/secrets/
    ```

3. Restore Jenkins backup

    ```bash
    # Stop Jenkins
    sudo systemctl stop jenkins

    # Restore backup
    sudo tar -xzf jenkins-backup-YYYYMMDD.tar.gz -C /

    # Set ownership
    sudo chown -R jenkins:jenkins /var/lib/jenkins

    # Start Jenkins
    sudo systemctl start jenkins
    ```

### Common Issues and Fixes

1. Jenkins not starting

    Cause: Java not found or port conflict

    Fix:

    ```bash
    # Check Java installation
    java -version

    # Check if port 8080 is in use
    sudo ss -tulnp | grep 8080

    # Check Jenkins logs
    sudo journalctl -u jenkins -n 50
    ```

2. Cannot push to Harbor from Jenkins

    Cause: Docker credentials or network issue

    Fix:

    ```bash
    # Test Docker login as Jenkins user
    sudo -u jenkins docker login harbor.arpansahu.space

    # Check Jenkins can reach Harbor
    sudo -u jenkins curl -I https://harbor.arpansahu.space
    ```

3. Pipeline fails with permission denied

    Cause: Jenkins doesn't have Docker access

    Fix:

    ```bash
    # Add Jenkins to Docker group
    sudo usermod -aG docker jenkins

    # Restart Jenkins
    sudo systemctl restart jenkins

    # Verify
    sudo -u jenkins docker ps
    ```

4. Email notifications not working

    Cause: SMTP configuration incorrect

    Fix:

    - Verify Mailjet API credentials in global variables
    - Check SMTP settings in Email Extension configuration
    - Send test email from Jenkins
    - Check Mailjet dashboard for send logs

5. GitHub webhook not triggering builds

    Cause: Webhook not configured or firewall blocking

    Fix:

    ```bash
    # Verify Jenkins is accessible from internet
    curl -I https://jenkins.arpansahu.space

    # Configure GitHub webhook
    # Repository → Settings → Webhooks → Add webhook
    # Payload URL: https://jenkins.arpansahu.space/github-webhook/
    # Content type: application/json
    # Events: Just the push event
    ```

### Security Best Practices

1. Use HTTPS only

    - Never access Jenkins over HTTP
    - Always use Nginx reverse proxy with TLS

2. Strong authentication

    ```bash
    # Enable security realm
    Dashboard → Manage Jenkins → Security → Security Realm
    Select: Jenkins' own user database
    ```

3. Enable CSRF protection

    Dashboard → Manage Jenkins → Security → CSRF Protection
    Check: Enable CSRF Protection

4. Limit build agent connections

    Dashboard → Manage Jenkins → Security → Agents
    Set: Fixed port (50000) or disable

5. Use credentials store

    - Never hardcode credentials in Jenkinsfile
    - Always use Jenkins credentials store
    - Rotate credentials regularly

6. Regular updates

    ```bash
    # Check for Jenkins updates
    Dashboard → Manage Jenkins → System Information

    # Update Jenkins
    sudo apt update
    sudo apt upgrade jenkins
    ```

7. Backup regularly

    ```bash
    # Automate with cron
    sudo crontab -e
    ```

    Add:
    ```bash
    0 2 * * * /usr/local/bin/backup-jenkins.sh
    ```

### Performance Optimization

1. Increase Java heap size

    ```bash
    sudo nano /etc/default/jenkins
    ```

    Add/modify:
    ```bash
    JAVA_ARGS="-Xmx2048m -Xms1024m"
    ```

    Restart Jenkins:
    ```bash
    sudo systemctl restart jenkins
    ```

2. Clean old builds

    Configure in project:
    - Discard old builds
    - Keep max 10 builds
    - Keep builds for 7 days

3. Use build agents

    Distribute builds across multiple machines instead of building everything on controller.

### Monitoring Jenkins

1. Check Jenkins system info

    Dashboard → Manage Jenkins → System Information

2. Monitor disk usage

    ```bash
    du -sh /var/lib/jenkins/*
    ```

3. Monitor build queue

    Dashboard → Build Queue (left sidebar)

4. View build history

    Dashboard → Build History (left sidebar)

### Final Verification Checklist

Run these commands to verify Jenkins is working:

```bash
# Check Jenkins service
sudo systemctl status jenkins

# Check Java version
java -version

# Check port binding
sudo ss -tulnp | grep 8080

# Check Nginx config
sudo nginx -t

# Test HTTPS access
curl -I https://jenkins.arpansahu.space

# Verify Docker access
sudo -u jenkins docker ps
```

Then test in browser:
- Access: https://jenkins.arpansahu.space
- Login with admin credentials
- Verify all 4 credentials exist
- Create test pipeline
- Run manual build
- Check email notification received

### What This Setup Provides

After following this guide, you will have:

1. Jenkins LTS with Java 21
2. HTTPS access via Nginx reverse proxy
3. 4 configured credentials (GitHub, Harbor, Jenkins API, Sentry)
4. Global environment variables for emails
5. Docker integration for builds
6. Email notifications via Mailjet
7. Build and deploy pipeline examples
8. Production-ready configuration
9. Automatic startup with systemd
10. Comprehensive monitoring and logging

### Example Configuration Summary

| Component | Value |
| --------- | ----- |
| Jenkins URL | https://jenkins.arpansahu.space |
| Jenkins Port | 8080 (localhost only) |
| Jenkins Home | /var/lib/jenkins |
| Java Version | OpenJDK 21 |
| Admin User | admin |
| Nginx Config | /etc/nginx/sites-available/services |

### Architecture Summary

```
Internet (HTTPS)
   │
   └─ Nginx (TLS Termination)
        │ [Wildcard Certificate: *.arpansahu.space]
        │
        └─ jenkins.arpansahu.space (Port 443 → 8080)
             │
             └─ Jenkins Controller
                  │
                  ├─ Credentials Store
                  │   ├─ github-auth
                  │   ├─ harbor-credentials
                  │   ├─ jenkins-admin-credentials
                  │   └─ sentry-auth-token
                  │
                  ├─ Build Pipelines
                  │   ├─ Jenkinsfile-build (Docker build + push)
                  │   └─ Jenkinsfile-deploy (Docker deploy)
                  │
                  └─ Integration
                      ├─ GitHub (webhooks)
                      ├─ Harbor (registry)
                      ├─ Docker (builds)
                      ├─ Mailjet (notifications)
                      └─ Sentry (error tracking)
```

### Key Rules to Remember

1. Jenkins port 8080 never exposed externally
2. Always use credentials store, never hardcode
3. Use Jenkinsfile for pipeline as code
4. Separate build and deploy pipelines
5. Store .env files outside repository
6. Enable email notifications for failures
7. Regular backups of /var/lib/jenkins
8. Keep Jenkins and plugins updated
9. Use Harbor for private registry
10. Monitor build queue and disk usage

### Next Steps

After setting up Jenkins:

1. Configure GitHub webhooks for automatic builds
2. Create pipelines for each project
3. Set up build agents for distributed builds
4. Configure Slack/Teams notifications
5. Implement automated testing in pipelines
6. Set up deployment approvals
7. Configure Jenkins metrics monitoring

My Jenkins instance: https://jenkins.arpansahu.space

For Harbor integration, see harbor.md documentation.
