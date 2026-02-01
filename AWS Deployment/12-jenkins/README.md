## Jenkins CI/CD Server

Jenkins is an open-source automation server for continuous integration and deployment.

### Quick Install

```bash
cd "AWS Deployment/jenkins"
chmod +x install.sh
./install.sh
```

### Installation Script

```bash file=install.sh
```

### Nginx Configuration

```nginx file=nginx.conf
```

### Manual Installation

#### 1. Install Java

```bash
sudo apt update
sudo apt install -y openjdk-17-jre
java -version
```

#### 2. Add Jenkins Repository

```bash
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
```

#### 3. Install Jenkins

```bash
sudo apt update
sudo apt install -y jenkins
```

#### 4. Start Jenkins

```bash
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins
```

#### 5. Get Initial Password

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

#### 6. Configure Nginx

```bash
sudo cp nginx.conf /etc/nginx/sites-available/jenkins
sudo ln -sf /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Initial Setup

1. **Access Jenkins:** https://jenkins.arpansahu.space
2. **Unlock Jenkins:** Paste the initial admin password
3. **Install Plugins:** Choose "Install suggested plugins"
4. **Create Admin User:**
   - Username: arpansahu
   - Password: Gandu302@jenkins
   - Email: admin@arpansahu.me
5. **Configure Jenkins URL:** https://jenkins.arpansahu.space

### Verification

```bash
# Check service
sudo systemctl status jenkins

# Check port
sudo ss -lntp | grep 8080

# Test local access
curl http://localhost:8080

# Test HTTPS
curl https://jenkins.arpansahu.space
```

### Common Tasks

**Restart Jenkins:**
```bash
sudo systemctl restart jenkins
```

**View logs:**
```bash
sudo journalctl -u jenkins -f
# Or
sudo tail -f /var/log/jenkins/jenkins.log
```

**Jenkins CLI:**
```bash
# Download CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Example command
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth arpansahu:token help
```

### Configuration Files

- **Jenkins Home:** `/var/lib/jenkins/`
- **Config:** `/var/lib/jenkins/config.xml`
- **Jobs:** `/var/lib/jenkins/jobs/`
- **Workspace:** `/var/lib/jenkins/workspace/`
- **Plugins:** `/var/lib/jenkins/plugins/`
- **Credentials:** `/var/lib/jenkins/credentials.xml`

### Environment Files

Access project environment files:
```bash
sudo vi /var/lib/jenkins/workspace/project-name/.env
```

### Backup

```bash
# Backup Jenkins home
sudo tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz /var/lib/jenkins

# Exclude workspaces and builds (smaller backup)
sudo tar -czf jenkins-config-backup-$(date +%Y%m%d).tar.gz \
  --exclude=/var/lib/jenkins/workspace \
  --exclude=/var/lib/jenkins/builds \
  /var/lib/jenkins
```

### Restore

```bash
# Stop Jenkins
sudo systemctl stop jenkins

# Restore
sudo tar -xzf jenkins-backup.tar.gz -C /

# Fix permissions
sudo chown -R jenkins:jenkins /var/lib/jenkins

# Start Jenkins
sudo systemctl start jenkins
```

### Troubleshooting

**Port 8080 in use:**
```bash
# Check what's using port 8080
sudo ss -lntp | grep 8080

# Change Jenkins port
sudo nano /etc/default/jenkins
# Change: HTTP_PORT=8080 to HTTP_PORT=8081

sudo systemctl restart jenkins
```

**Permission issues:**
```bash
# Fix Jenkins home permissions
sudo chown -R jenkins:jenkins /var/lib/jenkins
sudo systemctl restart jenkins
```

**Can't access via HTTPS:**
```bash
# Check nginx
sudo nginx -t
sudo tail -f /var/log/nginx/error.log

# Check Jenkins is running
sudo systemctl status jenkins
curl http://localhost:8080
```

### Security

**Enable CSRF Protection:**
- Manage Jenkins → Configure Global Security
- Enable "Prevent Cross Site Request Forgery exploits"

**Enable Security:**
- Use matrix-based security
- Limit anonymous access
- Require authentication for all operations

**API Token:**
- User → Configure → API Token → Add new Token
- Use for CLI and API access

### Plugins

**Essential Plugins:**
- Git Plugin
- Pipeline Plugin
- Docker Pipeline
- SSH Agent
- Credentials Binding
- Environment Injector

**Install plugin via CLI:**
```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ \
  -auth arpansahu:token install-plugin git
```

### Access Details

- **URL:** https://jenkins.arpansahu.space
- **Username:** arpansahu
- **Password:** Gandu302@jenkins
- **Port:** 8080 (localhost only)
- **Service:** `jenkins.service`

### Configuration Files

- Installation script: [`install.sh`](./install.sh)
- Nginx configuration: [`nginx.conf`](./nginx.conf)
- Service file: `/lib/systemd/system/jenkins.service`
