## AKHQ - Kafka Web UI (Docker + Form Authentication + TLS)

AKHQ is a modern Kafka GUI for managing topics, consumer groups, schemas, and more. This guide explains a **secure, production-ready AKHQ setup** with **form-based authentication**, **role-based access control**, and **TLS encryption**.

---

## Installing AKHQ (Docker Based)

### Step 1: Prerequisites

1. **Kafka cluster running** (see [Kafka.md](Kafka.md))

2. **Docker and Docker Compose installed**

   ```sh
   docker --version
   docker compose version
   ```

3. **Nginx configured with valid TLS certificates** for `kafka.arpansahu.space`

4. **Domain configured**: `kafka.arpansahu.space` pointing to your server IP

---

### Step 2: Setup Directory Structure

```sh
cd ~/kafka-deployment
# SSL directory should already exist from Kafka setup
```

---

### Step 3: Configuration

#### `.env` file additions

Add to your existing `.env`:

```bash
# AKHQ Configuration
AKHQ_PORT=8086
AKHQ_ADMIN_USERNAME=arpansahu
AKHQ_ADMIN_PASSWORD=your_admin_password
AKHQ_ADMIN_PASSWORD_HASH=$2a$12$ql789QKTS3ERMWC9jcCxvukKuPHx0Matk8dQrgb5yqVkIwLyDNCmC
AKHQ_USER_USERNAME=your_username
AKHQ_USER_PASSWORD=your_user_password
AKHQ_USER_PASSWORD_HASH=$2a$12$ql789QKTS3ERMWC9jcCxvukKuPHx0Matk8dQrgb5yqVkIwLyDNCmC
```

**⚠️ Important:** Generate proper BCrypt hashes for your passwords (see Password Hashing section below).

#### `docker-compose-akhq.yml`

Located in: `deployment/docker-compose-akhq.yml`

This file configures:
- **Micronaut Security** with cookie-based authentication
- **Form-based login** (web UI with username/password)
- **Role-based access control** (admin and reader roles)
- **BCrypt password hashing**
- **Kafka connection** via SASL_SSL

---

### Step 4: Generate BCrypt Password Hashes

AKHQ uses BCrypt hashes in `$2a$` format. Generate hashes for your passwords:

**Using Python:**

```python
import bcrypt

password = "your_password_here"
hash_bytes = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))
hash_str = hash_bytes.decode().replace('$2b$', '$2a$')  # AKHQ needs $2a$ format

print(f"Password: {password}")
print(f"BCrypt hash: {hash_str}")
print(f"For docker-compose: {hash_str.replace('$', '$$')}")
```

**Using htpasswd:**

```sh
htpasswd -bnBC 12 "" your_password | tr -d ':\n' | sed 's/$2y/$2a/'
```

**⚠️ Important:** In docker-compose YAML, escape `$` as `$$`:
- Actual hash: `$2a$12$abc123...`
- In YAML: `$$2a$$12$$abc123...`

---

### Step 5: Configure Nginx Reverse Proxy

Edit `/etc/nginx/sites-available/services`:

```nginx
# AKHQ Kafka UI
server {
    listen 443 ssl;
    server_name kafka.arpansahu.space;

    ssl_certificate /etc/nginx/ssl/arpansahu.space/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/arpansahu.space/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:8086;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

Reload nginx:

```sh
sudo nginx -t
sudo systemctl reload nginx
```

---

### Step 6: Start AKHQ

```sh
cd ~/kafka-deployment
docker compose -f docker-compose-akhq.yml up -d
```

**Wait for AKHQ to fully start (15-20 seconds):**

```sh
docker logs akhq --tail 50
```

Look for: `Startup completed`

---

### Step 7: Verify AKHQ is Running

**Check container status:**
```sh
docker ps | grep akhq
```

**Check authentication is enabled:**
```sh
curl -s http://localhost:8086/api/auths
```

Expected output:
```json
{"loginEnabled":true,"formEnabled":true,"version":"0.25.1"}
```

---

## Accessing AKHQ

1. **Open in browser:** https://kafka.arpansahu.space/ui

2. **Login with admin credentials:**
   - Username: `arpansahu` (or your `AKHQ_ADMIN_USERNAME`)
   - Password: `your_admin_password`

3. **You'll see the Kafka dashboard** with:
   - Topics list
   - Consumer groups
   - Brokers information
   - Schema registry (if configured)

---

## User Roles and Permissions

AKHQ uses a comprehensive role-based access control (RBAC) system.

### Available Roles

| Role | Resources | Actions | Description |
|------|-----------|---------|-------------|
| `topic-reader` | TOPIC, TOPIC_DATA | READ, READ_CONFIG | View topics and data |
| `topic-admin` | TOPIC, TOPIC_DATA | READ, CREATE, DELETE, UPDATE, ALTER_CONFIG | Full topic management |
| `topic-data-admin` | TOPIC_DATA | READ, CREATE, DELETE | Manage topic data only |
| `consumer-group-reader` | CONSUMER_GROUP | READ | View consumer groups |
| `consumer-group-admin` | CONSUMER_GROUP | READ, UPDATE_OFFSET, DELETE | Manage consumer groups |
| `connect-cluster-reader` | CONNECT_CLUSTER | READ | View Kafka Connect |
| `connector-admin` | CONNECTOR | READ, CREATE, DELETE, UPDATE_STATE | Manage connectors |
| `schema-reader` | SCHEMA | READ | View schemas |
| `schema-admin` | SCHEMA | READ, CREATE, UPDATE, DELETE | Manage schemas |
| `node-admin` | NODE | READ, READ_CONFIG, ALTER_CONFIG | Manage cluster nodes |
| `acl-reader` | ACL | READ | View ACLs |
| `ksqldb-admin` | KSQLDB | READ, EXECUTE | Execute ksqlDB queries |

### Default Groups

#### Admin Group
Has **all permissions** - full cluster access:

```yaml
groups:
  admin:
    - role: node-admin
    - role: topic-admin
    - role: topic-data-admin
    - role: consumer-group-admin
    - role: connect-cluster-reader
    - role: connector-admin
    - role: schema-admin
    - role: acl-reader
    - role: ksqldb-admin
```

#### Reader Group
**Read-only access** to most resources:

```yaml
groups:
  reader:
    - role: topic-reader
    - role: consumer-group-reader
    - role: connect-cluster-reader
    - role: schema-reader
```

---

## Adding More Users

### Step 1: Generate BCrypt Hash

```python
import bcrypt
password = "new_user_password"
hash_str = bcrypt.hashpw(password.encode(), bcrypt.gensalt(12)).decode().replace('$2b$', '$2a$')
print(hash_str)
```

### Step 2: Update docker-compose-akhq.yml

Add new user to `basic-auth` section:

```yaml
basic-auth:
  - username: arpansahu
    password: '$$2a$$12$$ql789QKTS3ERMWC9jcCxvukKuPHx0Matk8dQrgb5yqVkIwLyDNCmC'
    passwordHash: BCRYPT
    groups:
      - admin
  - username: newuser
    password: '$$2a$$12$$yourhashhere'
    passwordHash: BCRYPT
    groups:
      - reader  # or admin
```

### Step 3: Restart AKHQ

```sh
docker compose -f docker-compose-akhq.yml restart
```

---

## Creating Custom Groups

For specific permission sets, define custom groups:

### Example: Developer Group

```yaml
groups:
  developer:
    - role: topic-reader
    - role: consumer-group-reader
    - role: schema-admin  # Can manage schemas
```

### Example: Operator Group

```yaml
groups:
  operator:
    - role: topic-admin
    - role: consumer-group-admin
    - role: node-admin
```

Then assign users to custom groups:

```yaml
basic-auth:
  - username: developer1
    password: '$$2a$$12$$hash'
    passwordHash: BCRYPT
    groups:
      - developer
```

---

## Authentication Details

### How It Works

1. **Form-Based Login**: Web UI shows username/password form
2. **Micronaut Security**: Validates credentials against BCrypt hashes
3. **JWT Cookie**: Session stored in encrypted HTTP-only cookie
4. **Cookie-Based**: Session persists across page reloads
5. **Auto-Redirect**: After login, redirects to `/ui`

### Security Configuration

```yaml
micronaut:
  security:
    enabled: true                    # Activates security framework
    authentication: cookie           # Form-based with cookie session
    endpoints:
      login:
        path: "/login"               # Login endpoint
      logout:
        path: "/logout"
        get-allowed: true            # Allow GET logout
    token:
      jwt:
        enabled: true
        signatures:
          secret:
            generator:
              secret: "64+ character secret"  # Change in production!
```

### Session Management

- **Session duration**: 3600 seconds (1 hour)
- **Cookie attributes**: HTTPOnly, SameSite=Strict
- **JWT encryption**: HMAC-SHA256
- **Auto-renewal**: Cookie refreshed on activity

---

## Testing Authentication

### Test Login via curl

```sh
curl -i -X POST http://localhost:8086/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=arpansahu&password=your_password"
```

**Expected response:**
```
HTTP/1.1 303 See Other
location: /ui
set-cookie: JWT=eyJhbGciOiJIUzI1NiJ9...
```

### Test Authentication Status

```sh
curl -s http://localhost:8086/api/auths
```

**Expected response:**
```json
{"loginEnabled":true,"formEnabled":true,"version":"0.25.1"}
```

---

## Troubleshooting

### Issue: Login form doesn't work

**Check authentication is enabled:**
```sh
docker exec akhq printenv AKHQ_CONFIGURATION | grep -A 5 "micronaut:"
```

Should show:
```yaml
micronaut:
  security:
    enabled: true
    authentication: cookie
```

### Issue: "Invalid salt revision" error

**Cause:** BCrypt hash format is incorrect. AKHQ needs `$2a$` format, not `$2b$`.

**Solution:** Regenerate hash with `$2a$` format (see Password Hashing section).

### Issue: "Invalid credentials" with correct password

**Check BCrypt hash is correct:**

```python
import bcrypt
password = "your_password"
hash_from_config = "$2a$12$ql789QKTS3ERMWC9jcCxvukKuPHx0Matk8dQrgb5yqVkIwLyDNCmC"
print(bcrypt.checkpw(password.encode(), hash_from_config.replace('$2a$', '$2b$').encode()))
```

Should print `True`.

### Issue: loginEnabled is false

**Cause:** Micronaut security not enabled or misconfigured.

**Solution:** Verify `micronaut.security.enabled: true` in configuration.

### Issue: Cannot connect to Kafka

**Check Kafka connectivity:**
```sh
docker exec akhq kafka-console-consumer --bootstrap-server kafka-kraft:9092 \
  --consumer-config /ssl/client.properties \
  --topic test --from-beginning --max-messages 1
```

**Verify SSL truststore:**
```sh
docker exec akhq ls -la /ssl/
```

### Issue: 502 Bad Gateway from nginx

**Check AKHQ is running:**
```sh
docker ps | grep akhq
docker logs akhq --tail 50
```

**Test direct connection:**
```sh
curl http://localhost:8086/ui
```

---

## Maintenance

### View AKHQ Logs

```sh
docker logs akhq -f
```

### Restart AKHQ

```sh
docker compose -f docker-compose-akhq.yml restart
```

### Stop AKHQ

```sh
docker compose -f docker-compose-akhq.yml down
```

### Update Configuration

1. Edit `docker-compose-akhq.yml`
2. Restart AKHQ:
   ```sh
   docker compose -f docker-compose-akhq.yml down
   docker compose -f docker-compose-akhq.yml up -d
   ```

### Clear User Sessions

Restart AKHQ to invalidate all JWT cookies:

```sh
docker compose -f docker-compose-akhq.yml restart
```

---

## Advanced Features

### Connecting Multiple Kafka Clusters

Edit `docker-compose-akhq.yml` to add more connections:

```yaml
akhq:
  connections:
    kafka-cluster-1:
      properties:
        bootstrap.servers: "kafka-kraft-1:9092"
        # ... SSL config
    
    kafka-cluster-2:
      properties:
        bootstrap.servers: "kafka-kraft-2:9092"
        # ... SSL config
```

### Configuring Schema Registry

```yaml
akhq:
  connections:
    kafka-cluster:
      schema-registry:
        url: "https://schema-registry:8085"
        basic-auth-username: user
        basic-auth-password: pass
```

### Data Masking

Mask sensitive data in topic messages:

```yaml
security:
  data-masking:
    filters:
      - description: "Mask credit card numbers"
        search-regex: '"(card_number)":"[0-9]{16}"'
        replacement: '"$1":"****-****-****-****"'
      - description: "Mask email addresses"
        search-regex: '"(email)":"[^"]+@[^"]+"'
        replacement: '"$1":"***@***.com"'
```

---

## Security Best Practices

1. **Change JWT Secret** - Use 64+ character random string in production
2. **Use Strong Passwords** - Generate with `openssl rand -base64 32`
3. **Limit User Permissions** - Grant minimum required access
4. **Enable HTTPS Only** - Never expose HTTP port directly
5. **Regular Password Rotation** - Update hashes periodically
6. **Monitor Access Logs** - Review login attempts and actions
7. **Session Timeout** - Configure appropriate JWT expiration
8. **Network Isolation** - Keep AKHQ in private network, expose via nginx only

---

## Production Recommendations

1. **Change Default Passwords** - Use unique strong passwords
2. **Change JWT Secret** - Generate random 64+ character string
3. **Use LDAP/OIDC** - For enterprise SSO integration
4. **Enable Audit Logging** - Track all user actions
5. **Configure Backups** - Backup AKHQ configuration
6. **Set Resource Limits** - Configure Docker CPU and memory limits
7. **Monitor Performance** - Track response times and errors
8. **Update Regularly** - Keep AKHQ version current

---

## Alternative Authentication Methods

### LDAP Authentication

For centralized user management:

```yaml
micronaut:
  security:
    ldap:
      default:
        enabled: true
        context:
          server: 'ldap://ldap.company.com:389'
          managerDn: 'cn=admin,dc=company,dc=com'
          managerPassword: 'password'
        search:
          base: "ou=users,dc=company,dc=com"
```

### OIDC/OAuth2 (SSO)

For Single Sign-On with providers:

```yaml
micronaut:
  security:
    authentication: idtoken
    oauth2:
      clients:
        okta:
          client-id: "your-client-id"
          client-secret: "your-client-secret"
          openid:
            issuer: "https://your-tenant.okta.com"
```

---

## Monitoring

### Check User Sessions

View active JWT tokens in logs:

```sh
docker logs akhq | grep "JWT"
```

### Monitor Failed Logins

```sh
docker logs akhq | grep "login/failed"
```

### Track User Actions

Enable audit logging in configuration:

```yaml
akhq:
  audit:
    enabled: true
```

---

## References

- [AKHQ Documentation](https://akhq.io/docs/)
- [AKHQ GitHub](https://github.com/tchiotludo/akhq)
- [Micronaut Security](https://micronaut-projects.github.io/micronaut-security/latest/guide/)
- [BCrypt Password Hashing](https://en.wikipedia.org/wiki/Bcrypt)
