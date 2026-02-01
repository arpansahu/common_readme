## PostgreSQL Server (System Service)

PostgreSQL is a powerful, open-source relational database system. This setup installs PostgreSQL as a native system service with remote access enabled.

---

## Test Files Overview

| Test File | Where to Run | Connection Type | Purpose |
|-----------|-------------|-----------------|---------|
| `test_postgres_localhost.py` | **On Server** | localhost:5432 | Test PostgreSQL on server without TLS |
| `test_postgres_mac.sh` | **From Mac** | 192.168.1.200:5432 | Test PostgreSQL from Mac (direct IP, no TLS) |
| `test_postgres_domain_tls.sh` | **From Mac** | postgres.arpansahu.space:9552 | Test PostgreSQL from Mac with TLS via domain |

**Quick Test Commands:**
```bash
# On Server (localhost)
python3 test_postgres_localhost.py

# From Mac (direct IP, no TLS)
PG_PASSWORD=your_password ./test_postgres_mac.sh

# From Mac (domain with TLS)
PG_PASSWORD=your_password ./test_postgres_domain_tls.sh
```

**CLI Testing (psql):**
```bash
# On Server (localhost) - As postgres superuser
sudo -u postgres psql -c "SELECT version();"
sudo -u postgres psql -c "\l"  # List databases

# On Server (localhost) - With password auth
psql -h localhost -U postgres -d postgres -c "SELECT current_database(), current_user, version();"

# From Mac (direct IP, no TLS)
export PGPASSWORD=your_password
psql -h 192.168.1.200 -p 5432 -U postgres -d postgres -c "SELECT version();"

# From Mac (domain with TLS)
export PGPASSWORD=your_password
psql "host=postgres.arpansahu.space port=9552 user=postgres dbname=postgres sslmode=require" -c "SELECT version();"

# Interactive connection with TLS
psql "host=postgres.arpansahu.space port=9552 user=postgres dbname=postgres sslmode=require"
```

---

## Step-by-Step Installation Guide

### Step 1: Create Environment Configuration

First, create the environment configuration file that will store your PostgreSQL password.

**Create `.env.example` (Template file):**

```bash
# PostgreSQL Configuration
POSTGRES_PASSWORD=your_secure_password_here
```

**Create your actual `.env` file:**

```bash
cd "AWS Deployment/Postgres"
cp .env.example .env
nano .env
```

**Your `.env` file should look like this (with your actual password):**

```bash
# PostgreSQL Configuration
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
```

**⚠️ Important:** 
- Always use a strong password in production!
- Never commit your `.env` file to version control
- Keep the `.env.example` file as a template

---

### Step 2: Create Installation Script

The `install.sh` script installs PostgreSQL and configures it for remote access.

**Content of `install.sh`:**

```bash
#!/bin/bash
set -e

echo "=== PostgreSQL Installation Script ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
    echo -e "${GREEN}Loaded configuration from .env file${NC}"
else
    echo -e "${YELLOW}Warning: .env file not found. Using defaults.${NC}"
    echo -e "${YELLOW}Please copy .env.example to .env and configure it.${NC}"
fi

# Configuration with defaults
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-changeme}"

echo -e "${YELLOW}Step 1: Installing PostgreSQL${NC}"
sudo apt update
sudo apt install -y postgresql postgresql-contrib

echo -e "${YELLOW}Step 2: Starting PostgreSQL${NC}"
sudo systemctl start postgresql
sudo systemctl enable postgresql

echo -e "${YELLOW}Step 3: Setting postgres user password${NC}"
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$POSTGRES_PASSWORD';"

echo -e "${YELLOW}Step 4: Configuring PostgreSQL for remote connections${NC}"
# Backup original config
sudo cp /etc/postgresql/*/main/postgresql.conf /etc/postgresql/*/main/postgresql.conf.bak
sudo cp /etc/postgresql/*/main/pg_hba.conf /etc/postgresql/*/main/pg_hba.conf.bak

# Allow remote connections
PG_VERSION=$(ls /etc/postgresql/)
echo "listen_addresses = '*'" | sudo tee -a /etc/postgresql/$PG_VERSION/main/postgresql.conf

# Allow password authentication
echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /etc/postgresql/$PG_VERSION/main/pg_hba.conf
echo "host    all             all             ::/0                    md5" | sudo tee -a /etc/postgresql/$PG_VERSION/main/pg_hba.conf

echo -e "${YELLOW}Step 5: Restarting PostgreSQL${NC}"
sudo systemctl restart postgresql

echo -e "${YELLOW}Step 6: Verifying Installation${NC}"
sudo -u postgres psql -c "SELECT version();"

echo -e "${GREEN}PostgreSQL installed successfully!${NC}"
echo -e "Connection details:"
echo -e "  Host: localhost (or 192.168.1.200)"
echo -e "  Port: 5432"
echo -e "  User: postgres"
echo -e "  Password: $POSTGRES_PASSWORD"
echo ""
echo -e "${YELLOW}Test connection:${NC}"
echo "  psql -h localhost -U postgres -d postgres"
```

**What this script does:**
- Installs PostgreSQL and contrib packages
- Enables PostgreSQL service to start on boot
- Sets password for `postgres` superuser
- Configures PostgreSQL to accept remote connections
- Updates authentication to use password (md5)
- Backs up original configuration files

**Run the installation:**

```bash
chmod +x install.sh
./install.sh
```

**Expected output:**
```
=== PostgreSQL Installation Script ===
Loaded configuration from .env file
Step 1: Installing PostgreSQL
Step 2: Starting PostgreSQL
Step 3: Setting postgres user password
ALTER ROLE
Step 4: Configuring PostgreSQL for remote connections
Step 5: Restarting PostgreSQL
Step 6: Verifying Installation
PostgreSQL installed successfully!
```

---

## Testing Your PostgreSQL Installation

### Test 1: Check Service Status

Verify that PostgreSQL service is running:

```bash
# Check service status
sudo systemctl status postgresql

# Check if port is listening
sudo ss -lntp | grep 5432
```

**Expected output:**
```
Active: active (exited) since ...
LISTEN 0 244 0.0.0.0:5432 0.0.0.0:*
```

---

### Test 2: Connect Locally

Test PostgreSQL connection from the server:

```bash
# Connect as postgres user
sudo -u postgres psql

# Or with password authentication
psql -h localhost -U postgres -d postgres
# Enter password when prompted
```

---

### Test 3: Check Version and Databases

```bash
# Check version
sudo -u postgres psql -c "SELECT version();"

# List databases
sudo -u postgres psql -c "\l"

# List users
sudo -u postgres psql -c "\du"
```

---

## Automated Connection Testing

### Test Script 1: Server Connection Test (Python)

This script tests PostgreSQL connectivity from the server using psycopg2.

**Create `test_postgres_server.py` file:**

```python
#!/usr/bin/env python3
"""
PostgreSQL Server Connection Test
Tests PostgreSQL connectivity from the server using psycopg2
"""

import sys

try:
    import psycopg2
except ImportError:
    print("✗ Error: psycopg2 not installed")
    print("Install with: pip3 install psycopg2-binary")
    sys.exit(1)

def test_postgres():
    try:
        print("=== Testing PostgreSQL Connection from Server ===\n")
        
        # Connection parameters
        conn_params = {
            'host': 'localhost',
            'port': 5432,
            'user': 'postgres',
            'password': '${POSTGRES_PASSWORD}',
            'database': 'postgres'
        }
        
        print(f"Connecting to PostgreSQL at {conn_params['host']}:{conn_params['port']}...")
        conn = psycopg2.connect(**conn_params)
        print("✓ Connection successful\n")
        
        # Get version
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        print(f"✓ PostgreSQL version: {version.split(',')[0]}\n")
        
        # Test database operations
        cursor.execute("CREATE TABLE IF NOT EXISTS test_table (id SERIAL PRIMARY KEY, data TEXT);")
        print("✓ Table created: test_table\n")
        
        cursor.execute("INSERT INTO test_table (data) VALUES (%s) RETURNING id;", ("Hello from Server!",))
        test_id = cursor.fetchone()[0]
        conn.commit()
        print(f"✓ Record inserted with ID: {test_id}\n")
        
        cursor.execute("SELECT * FROM test_table WHERE id = %s;", (test_id,))
        record = cursor.fetchone()
        print(f"✓ Record retrieved: ID={record[0]}, Data={record[1]}\n")
        
        # Clean up
        cursor.execute("DROP TABLE test_table;")
        conn.commit()
        print("✓ Test table dropped\n")
        
        cursor.close()
        conn.close()
        
        print("✓ All tests passed!")
        print("✓ PostgreSQL is working correctly\n")
        return 0
        
    except psycopg2.OperationalError as e:
        print(f"✗ Connection Error: {e}")
        print("  Check if PostgreSQL is running: sudo systemctl status postgresql")
        return 1
    except psycopg2.Error as e:
        print(f"✗ Database Error: {e}")
        return 1
    except Exception as e:
        print(f"✗ Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(test_postgres())
```

**Run on server:**

```bash
# Install psycopg2 if not already installed
pip3 install psycopg2-binary

# Run the test
python3 test_postgres_server.py
```

**Expected output:**
```
=== Testing PostgreSQL Connection from Server ===

Connecting to PostgreSQL at localhost:5432...
✓ Connection successful

✓ PostgreSQL version: PostgreSQL 14.x

✓ Table created: test_table

✓ Record inserted with ID: 1

✓ Record retrieved: ID=1, Data=Hello from Server!

✓ Test table dropped

✓ All tests passed!
✓ PostgreSQL is working correctly
```

---

### Test Script 2: Mac Connection Test (Shell Script)

This script tests PostgreSQL connectivity from your Mac.

**Create `test_postgres_mac.sh` file:**

```bash
#!/bin/bash

# PostgreSQL Mac Connection Test
# Tests PostgreSQL connectivity from your Mac

set -e

echo "=== Testing PostgreSQL Connection from Mac ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PG_HOST="${PG_HOST:-192.168.1.200}"
PG_PORT="${PG_PORT:-5432}"
PG_USER="${PG_USER:-postgres}"
PG_PASSWORD="${PG_PASSWORD:-changeme}"
PG_DATABASE="${PG_DATABASE:-postgres}"

# Test 1: Check if PostgreSQL is accessible
echo -e "${YELLOW}Test 1: Checking PostgreSQL accessibility...${NC}"
if command -v psql &> /dev/null; then
    export PGPASSWORD="$PG_PASSWORD"
    if psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DATABASE" -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PostgreSQL is accessible${NC}"
    else
        echo -e "${RED}✗ Failed to connect to PostgreSQL${NC}"
        echo "  Make sure PostgreSQL is configured to allow remote connections"
        exit 1
    fi
else
    echo -e "${RED}✗ psql command not found${NC}"
    echo "  Install with: brew install postgresql"
    exit 1
fi
echo ""

# Test 2: Get PostgreSQL version
echo -e "${YELLOW}Test 2: Getting PostgreSQL version...${NC}"
VERSION=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DATABASE" -t -c "SELECT version();" 2>/dev/null | xargs)
echo -e "${GREEN}✓ PostgreSQL version: ${VERSION:0:50}...${NC}"
echo ""

# Test 3: List databases
echo -e "${YELLOW}Test 3: Listing databases...${NC}"
DATABASES=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DATABASE" -t -c "\l" 2>/dev/null | grep -c "|")
echo -e "${GREEN}✓ Found $DATABASES databases${NC}"
echo ""

# Test 4: Create test table
echo -e "${YELLOW}Test 4: Creating test table...${NC}"
psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DATABASE" -c "CREATE TABLE IF NOT EXISTS mac_test_table (id SERIAL PRIMARY KEY, data TEXT, created_at TIMESTAMP DEFAULT NOW());" > /dev/null 2>&1
echo -e "${GREEN}✓ Test table created${NC}"
echo ""

# Test 5: Insert and retrieve data
echo -e "${YELLOW}Test 5: Testing data operations...${NC}"
psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DATABASE" -c "INSERT INTO mac_test_table (data) VALUES ('Hello from Mac!');" > /dev/null 2>&1
RECORD=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DATABASE" -t -c "SELECT data FROM mac_test_table ORDER BY id DESC LIMIT 1;" 2>/dev/null | xargs)
echo -e "${GREEN}✓ Record inserted and retrieved: '$RECORD'${NC}"
echo ""

# Test 6: Clean up
echo -e "${YELLOW}Test 6: Cleaning up test table...${NC}"
psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DATABASE" -c "DROP TABLE IF EXISTS mac_test_table;" > /dev/null 2>&1
echo -e "${GREEN}✓ Test table dropped${NC}"
echo ""

# Unset password
unset PGPASSWORD

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ All tests passed!${NC}"
echo -e "${GREEN}✓ PostgreSQL is working correctly${NC}"
echo -e "${GREEN}========================================${NC}"
```

**Run from your Mac:**

```bash
# Make script executable
chmod +x test_postgres_mac.sh

# Set environment variables (optional)
export PG_HOST=192.168.1.200
export PG_USER=postgres
export PG_PASSWORD=your_password

# Run the test
./test_postgres_mac.sh
```

**Expected output:**
```
=== Testing PostgreSQL Connection from Mac ===

Test 1: Checking PostgreSQL accessibility...
✓ PostgreSQL is accessible

Test 2: Getting PostgreSQL version...
✓ PostgreSQL version: PostgreSQL 14.x (Ubuntu 14.x-1.pgdg22.04+1) on x86...

Test 3: Listing databases...
✓ Found 3 databases

Test 4: Creating test table...
✓ Test table created

Test 5: Testing data operations...
✓ Record inserted and retrieved: 'Hello from Mac!'

Test 6: Cleaning up test table...
✓ Test table dropped

========================================
✓ All tests passed!
✓ PostgreSQL is working correctly
========================================
```

---

## Secure Remote Access via Nginx TLS

For secure connections from outside your local network, you can set up an nginx stream proxy with TLS encryption.

### Step 1: Create Nginx Stream Configuration

**Create `nginx-stream.conf` file:**

```nginx
# Add this to the stream block in /etc/nginx/nginx.conf

    # PostgreSQL TCP Passthrough (PostgreSQL handles SSL itself)
    # Note: Unlike Redis, PostgreSQL uses binary protocol that cannot work
    # through nginx SSL termination. We use TCP passthrough instead.
    upstream postgres_backend {
        server 127.0.0.1:5432;
    }

    server {
        listen 9552;
        proxy_pass postgres_backend;
        proxy_connect_timeout 10s;
        proxy_timeout 300s;
    }
```

**Important: Why TCP Passthrough Instead of SSL Termination?**

PostgreSQL uses a complex binary protocol with specific handshake requirements that get corrupted when nginx terminates SSL and forwards plain TCP. This is different from Redis, which uses a simple text-based protocol that works fine with nginx SSL termination.

With TCP passthrough:
- Nginx simply forwards TCP packets without decryption (no SSL configuration on nginx)
- PostgreSQL handles SSL/TLS encryption itself (already configured in `postgresql.conf` with `ssl=on`)
- Connection is still encrypted end-to-end using PostgreSQL's native SSL
- Port 9552 is used instead of default 5432 for security (avoiding bot scans on standard ports)

---

### Step 2: Configure Router Port Forwarding

**⚠️ Required for external access (from outside your home network)**

If you want to access PostgreSQL from outside your local network (e.g., from mobile data, other locations), you need to configure port forwarding on your router.

**Steps for Airtel Router:**

1. **Login to router admin panel:**
   - Open browser and go to: `http://192.168.1.1`
   - Enter admin credentials

2. **Navigate to Port Forwarding:**
   - Go to `NAT` → `Port Forwarding` tab
   - Click "Add new rule"

3. **Configure port forwarding rule:**
   - **Service Name:** User Define
   - **External Start Port:** 9552
   - **External End Port:** 9552
   - **Internal Start Port:** 9552
   - **Internal End Port:** 9552
   - **Server IP Address:** 192.168.1.200 (your server's local IP)
   - **Protocol:** TCP (or TCP/UDP)

4. **Activate the rule:**
   - Click save/apply
   - The rule should appear in the port forwarding list with status "Active"

**Verify port forwarding:**
```bash
# From external network (mobile data or different location)
psql "host=postgres.arpansahu.space port=9552 user=postgres dbname=postgres sslmode=require" -c "SELECT version();"
```

**Note:** Port forwarding is NOT required if you only access PostgreSQL from devices on the same local network (192.168.1.x).

---

### Step 3: Create Automated Setup Script

**Create `add-nginx-stream.sh` file:**

```bash
#!/bin/bash
set -e

echo "=== PostgreSQL Nginx Stream Configuration Script ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run with sudo${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Backing up nginx.conf${NC}"
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup-postgres-$(date +%Y%m%d-%H%M%S)

echo -e "${YELLOW}Step 2: Adding PostgreSQL stream configuration${NC}"
# Check if stream block already exists
if ! grep -q "stream {" /etc/nginx/nginx.conf; then
    echo -e "${YELLOW}Stream block not found, adding it to nginx.conf${NC}"
    cat >> /etc/nginx/nginx.conf << 'EOF'

# Stream configuration for TCP/UDP load balancing
stream {
    # PostgreSQL TCP Passthrough (PostgreSQL handles SSL itself)
    upstream postgres_backend {
        server 127.0.0.1:5432;
    }

    server {
        listen 9552;
        proxy_pass postgres_backend;
        proxy_connect_timeout 10s;
        proxy_timeout 300s;
    }
}
EOF
    echo -e "${GREEN}Stream block with PostgreSQL configuration added${NC}"
else
    # Check if PostgreSQL stream config already exists
    if grep -q "# PostgreSQL" /etc/nginx/nginx.conf; then
        echo -e "${YELLOW}PostgreSQL stream configuration already exists, skipping...${NC}"
    else
        # Get the script directory
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        
        # Insert the configuration before the closing brace of the stream block
        # Read the stream config and append it
        grep -v "^# Add this to" "$SCRIPT_DIR/nginx-stream.conf" | \
            sed -i '/^stream {/r /dev/stdin' /etc/nginx/nginx.conf
        
        echo -e "${GREEN}PostgreSQL stream configuration added${NC}"
    fi
fi

echo -e "${YELLOW}Step 3: Testing nginx configuration${NC}"
if nginx -t; then
    echo -e "${GREEN}Nginx configuration is valid${NC}"
else
    echo -e "${RED}Nginx configuration test failed!${NC}"
    echo "Restoring backup..."
    cp /etc/nginx/nginx.conf.backup-postgres-$(date +%Y%m%d-%H%M%S) /etc/nginx/nginx.conf
    exit 1
fi

echo -e "${YELLOW}Step 4: Reloading nginx${NC}"
systemctl reload nginx

echo -e "${YELLOW}Step 5: Checking if port 9552 is listening${NC}"
sleep 2
if ss -lntp | grep -q ":9552"; then
    echo -e "${GREEN}✓ Nginx is listening on port 9552${NC}"
else
    echo -e "${RED}✗ Port 9552 is not listening${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}PostgreSQL Nginx Stream Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "PostgreSQL is now accessible via:"
echo "  - Local: localhost:5432"
echo "  - TLS (via nginx): postgres.arpansahu.space:9552"
echo ""
echo "Test connection:"
echo "  psql 'host=postgres.arpansahu.space port=9552 user=postgres dbname=postgres sslmode=require'"
```

**Run the setup:**

```bash
chmod +x add-nginx-stream.sh
sudo ./add-nginx-stream.sh
```

---

### Step 4: Test TLS Connection from Mac

**Create `test_postgres_mac_tls.sh` file:**

```bash
#!/bin/bash

# PostgreSQL Mac TLS Connection Test (via Nginx)
# Tests PostgreSQL connectivity from your Mac through nginx TLS proxy

set -e

echo "=== Testing PostgreSQL TLS Connection from Mac (via Nginx) ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PG_HOST="${PG_HOST:-postgres.arpansahu.space}"
PG_PORT="${PG_PORT:-9552}"
PG_USER="${PG_USER:-postgres}"
PG_PASSWORD="${PG_PASSWORD:-changeme}"
PG_DATABASE="${PG_DATABASE:-postgres}"

# Test 1: Check if PostgreSQL is accessible via TLS
echo -e "${YELLOW}Test 1: Checking PostgreSQL TLS accessibility...${NC}"
if command -v psql &> /dev/null; then
    export PGPASSWORD="$PG_PASSWORD"
    if psql "host=$PG_HOST port=$PG_PORT user=$PG_USER dbname=$PG_DATABASE sslmode=require" -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PostgreSQL is accessible via TLS (nginx proxy)${NC}"
    else
        echo -e "${RED}✗ Failed to connect to PostgreSQL via TLS${NC}"
        echo "  Make sure nginx stream is configured and port 9552 is open"
        exit 1
    fi
else
    echo -e "${RED}✗ psql command not found${NC}"
    echo "  Install with: brew install postgresql"
    exit 1
fi
echo ""

# Test 2: Verify TLS connection is being used
echo -e "${YELLOW}Test 2: Verifying TLS connection...${NC}"
CONNECTION_INFO=$(psql "host=$PG_HOST port=$PG_PORT user=$PG_USER dbname=$PG_DATABASE sslmode=require" -t -c "SELECT 'Connected via TLS on port $PG_PORT';" 2>/dev/null | xargs)
echo -e "${GREEN}✓ $CONNECTION_INFO${NC}"
echo ""

# Test 3: Get PostgreSQL version via TLS
echo -e "${YELLOW}Test 3: Getting PostgreSQL version via TLS...${NC}"
VERSION=$(psql "host=$PG_HOST port=$PG_PORT user=$PG_USER dbname=$PG_DATABASE sslmode=require" -t -c "SELECT version();" 2>/dev/null | xargs)
echo -e "${GREEN}✓ PostgreSQL version: ${VERSION:0:50}...${NC}"
echo ""

# Test 4: List databases via TLS
echo -e "${YELLOW}Test 4: Listing databases via TLS...${NC}"
DATABASES=$(psql "host=$PG_HOST port=$PG_PORT user=$PG_USER dbname=$PG_DATABASE sslmode=require" -t -c "\l" 2>/dev/null | grep -c "|")
echo -e "${GREEN}✓ Found $DATABASES databases${NC}"
echo ""

# Test 5: Create test table via TLS
echo -e "${YELLOW}Test 5: Creating test table via TLS...${NC}"
psql "host=$PG_HOST port=$PG_PORT user=$PG_USER dbname=$PG_DATABASE sslmode=require" -c "CREATE TABLE IF NOT EXISTS mac_tls_test_table (id SERIAL PRIMARY KEY, data TEXT, created_at TIMESTAMP DEFAULT NOW());" > /dev/null 2>&1
echo -e "${GREEN}✓ Test table created via TLS${NC}"
echo ""

# Test 6: Insert and retrieve data via TLS
echo -e "${YELLOW}Test 6: Testing data operations via TLS...${NC}"
psql "host=$PG_HOST port=$PG_PORT user=$PG_USER dbname=$PG_DATABASE sslmode=require" -c "INSERT INTO mac_tls_test_table (data) VALUES ('Hello from Mac via TLS!');" > /dev/null 2>&1
RECORD=$(psql "host=$PG_HOST port=$PG_PORT user=$PG_USER dbname=$PG_DATABASE sslmode=require" -t -c "SELECT data FROM mac_tls_test_table ORDER BY id DESC LIMIT 1;" 2>/dev/null | xargs)
echo -e "${GREEN}✓ Record inserted and retrieved via TLS: '$RECORD'${NC}"
echo ""

# Test 7: Clean up
echo -e "${YELLOW}Test 7: Cleaning up test table...${NC}"
psql "host=$PG_HOST port=$PG_PORT user=$PG_USER dbname=$PG_DATABASE sslmode=require" -c "DROP TABLE IF EXISTS mac_tls_test_table;" > /dev/null 2>&1
echo -e "${GREEN}✓ Test table dropped${NC}"
echo ""

# Unset password
unset PGPASSWORD

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ All TLS tests passed!${NC}"
echo -e "${GREEN}✓ PostgreSQL is working correctly via Nginx TLS proxy${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Connection used:"
echo "  Host: $PG_HOST"
echo "  Port: $PG_PORT (TLS via nginx)"
echo "  SSL Mode: require"
```

**Run from your Mac:**

```bash
# Make script executable
chmod +x test_postgres_mac_tls.sh

# Set password and run
PG_PASSWORD=your_password ./test_postgres_mac_tls.sh
```

**Expected output:**
```
=== Testing PostgreSQL TLS Connection from Mac (via Nginx) ===

Test 1: Checking PostgreSQL TLS accessibility...
✓ PostgreSQL is accessible via TLS (nginx proxy)

Test 2: Verifying TLS connection...
✓ Connected via TLS on port 9552

Test 3: Getting PostgreSQL version via TLS...
✓ PostgreSQL version: PostgreSQL 14.x (Ubuntu 14.x-1.pgdg22.04+1) on x86...

Test 4: Listing databases via TLS...
✓ Found 3 databases

Test 5: Creating test table via TLS...
✓ Test table created via TLS

Test 6: Testing data operations via TLS...
✓ Record inserted and retrieved via TLS: 'Hello from Mac via TLS!'

Test 7: Cleaning up test table...
✓ Test table dropped

========================================
✓ All TLS tests passed!
✓ PostgreSQL is working correctly via Nginx TLS proxy
========================================

Connection used:
  Host: postgres.arpansahu.space
  Port: 9552 (TLS via nginx)
  SSL Mode: require
```

---

## Connection Details Summary

After successful installation, your PostgreSQL setup will have:

- **Service Type:** Native system service (not Docker)
- **Host (Local):** `192.168.1.200` or `localhost`
- **Port (Local):** `5432`
- **Host (TLS/Remote):** `postgres.arpansahu.space`
- **Port (TLS/Remote):** `9552` (via nginx)
- **Superuser:** `postgres`
- **Password:** `${POSTGRES_PASSWORD}` (from your .env file)
- **Remote Access:** Enabled (direct and via TLS proxy)
- **Authentication:** MD5 password authentication
- **TLS Encryption:** Available via nginx stream on port 9552

---

## Database Management

### Create Database

```bash
# Method 1: Using createdb command
sudo -u postgres createdb myapp_db

# Method 2: Using SQL
sudo -u postgres psql -c "CREATE DATABASE myapp_db;"
```

---

### Create User and Grant Permissions

```bash
sudo -u postgres psql << EOF
CREATE USER myapp_user WITH PASSWORD 'myapp_password';
GRANT ALL PRIVILEGES ON DATABASE myapp_db TO myapp_user;
ALTER DATABASE myapp_db OWNER TO myapp_user;
EOF
```

---

### Connect to Database

```bash
# As postgres superuser
sudo -u postgres psql -d myapp_db

# As custom user
psql -h localhost -U myapp_user -d myapp_db

# From remote machine
psql -h 192.168.1.200 -U myapp_user -d myapp_db
```

---

### Backup Database

```bash
# Backup single database
sudo -u postgres pg_dump myapp_db > myapp_db_backup_$(date +%Y%m%d).sql

# Backup all databases
sudo -u postgres pg_dumpall > all_databases_backup_$(date +%Y%m%d).sql

# Compressed backup
sudo -u postgres pg_dump myapp_db | gzip > myapp_db_backup_$(date +%Y%m%d).sql.gz
```

---

### Restore Database

```bash
# Restore from backup
sudo -u postgres psql myapp_db < myapp_db_backup_20240101.sql

# Restore compressed backup
gunzip < myapp_db_backup_20240101.sql.gz | sudo -u postgres psql myapp_db

# Restore all databases
sudo -u postgres psql < all_databases_backup_20240101.sql
```

---

## Using PostgreSQL in Your Applications

### Python Connection Example

Install the psycopg2 library:

```bash
pip install psycopg2-binary
```

**Basic connection:**

```python
import psycopg2

# Connection parameters
conn = psycopg2.connect(
    host='192.168.1.200',
    port=5432,
    database='myapp_db',
    user='myapp_user',
    password='myapp_password'
)

# Create cursor
cursor = conn.cursor()

# Execute query
cursor.execute("SELECT * FROM users;")
rows = cursor.fetchall()

for row in rows:
    print(row)

# Close connection
cursor.close()
conn.close()
```

---

### Django Configuration

Add PostgreSQL configuration in `settings.py`:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'myapp_db',
        'USER': 'myapp_user',
        'PASSWORD': 'myapp_password',
        'HOST': '192.168.1.200',
        'PORT': '5432',
    }
}
```

**Install psycopg2:**

```bash
pip install psycopg2-binary
```

**Run migrations:**

```bash
python manage.py migrate
```

---

## Troubleshooting

### Service Issues

If PostgreSQL service is not running:

```bash
# Check service status
sudo systemctl status postgresql

# Start service
sudo systemctl start postgresql

# Restart service
sudo systemctl restart postgresql

# View logs
sudo journalctl -u postgresql -n 50
```

---

### Connection Refused

If you cannot connect remotely:

```bash
# Check if PostgreSQL is listening on all interfaces
sudo ss -lntp | grep 5432
# Should show: 0.0.0.0:5432

# Check postgresql.conf
PG_VERSION=$(ls /etc/postgresql/)
sudo grep listen_addresses /etc/postgresql/$PG_VERSION/main/postgresql.conf
# Should show: listen_addresses = '*'

# Check pg_hba.conf for remote access rules
sudo cat /etc/postgresql/$PG_VERSION/main/pg_hba.conf | grep "0.0.0.0/0"
# Should show: host    all             all             0.0.0.0/0               md5

# Restart after changes
sudo systemctl restart postgresql
```

---

### Authentication Failed

If you get "authentication failed" errors:

```bash
# Reset postgres password
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'new_password';"

# Check pg_hba.conf authentication method
PG_VERSION=$(ls /etc/postgresql/)
sudo cat /etc/postgresql/$PG_VERSION/main/pg_hba.conf

# Ensure md5 authentication is enabled (not peer or ident)
```

---

### Nginx Connection Issues (Port 9552)

**"Server closed connection unexpectedly" error:**

This occurs when trying to use nginx SSL termination with PostgreSQL. Unlike Redis (text protocol), PostgreSQL uses a binary protocol that cannot work through nginx SSL termination.

**Solution:** Use TCP passthrough configuration (already configured in our setup):
- Nginx configuration should NOT have SSL directives (`listen 9552;` instead of `listen 9552 ssl;`)
- PostgreSQL handles SSL encryption itself (configured with `ssl=on` in postgresql.conf)
- Connection is still encrypted end-to-end, just by PostgreSQL instead of nginx

**Verify configuration:**
```bash
# Check nginx stream configuration
sudo grep -A 10 "postgres_backend" /etc/nginx/nginx.conf
# Should NOT show ssl_certificate or ssl_certificate_key

# Check if port 9552 is listening
sudo ss -lntp | grep 9552
# Should show nginx listening on port 9552

# Test connection from Mac
psql "host=postgres.arpansahu.space port=9552 user=postgres dbname=postgres sslmode=prefer"
```

**Why TCP passthrough instead of SSL termination?**
- **Redis:** Simple text-based protocol → Works with nginx SSL termination
- **PostgreSQL:** Complex binary protocol with handshake → Requires TCP passthrough
- Both methods provide end-to-end encryption, just handled at different layers

---

### Port Already in Use

If port 5432 is already in use:

```bash
# Check what's using the port
sudo ss -lntp | grep 5432

# Kill the process if needed
sudo kill -9 <PID>

# Or change PostgreSQL port in postgresql.conf
```

---

## Security Best Practices

1. **Strong Passwords:** Always use strong passwords for database users
2. **Limited Access:** Only allow remote access from trusted IPs
3. **Regular Backups:** Schedule automated backups
4. **Update Regularly:** Keep PostgreSQL updated
5. **User Permissions:** Follow principle of least privilege
6. **TLS Encryption:** PostgreSQL handles its own SSL/TLS (configured with `ssl=on`)
7. **Non-Standard Ports:** Use port 9552 via nginx to avoid bot scanning of default port 5432
8. **Firewall Rules:** Close external access to port 5432, only expose port 9552
9. **Monitor Logs:** Regularly check PostgreSQL logs for suspicious activity

---

## Quick Reference

### Important Files

- **Environment template:** [`.env.example`](./.env.example)
- **Environment config:** `.env` (create from .env.example)
- **Installation script:** [`install.sh`](./install.sh)
- **Nginx stream config:** [`nginx-stream.conf`](./nginx-stream.conf)
- **Nginx setup script:** [`add-nginx-stream.sh`](./add-nginx-stream.sh)
- **Test script (localhost):** [`test_postgres_localhost.py`](./test_postgres_localhost.py) - Run on server
- **Test script (direct IP):** [`test_postgres_mac.sh`](./test_postgres_mac.sh) - Run from Mac
- **Test script (domain TLS):** [`test_postgres_domain_tls.sh`](./test_postgres_domain_tls.sh) - Run from Mac

### Important Commands

```bash
# Install PostgreSQL
./install.sh

# Set up nginx TLS proxy (optional)
sudo ./add-nginx-stream.sh

# Service management
sudo systemctl start postgresql
sudo systemctl stop postgresql
sudo systemctl restart postgresql
sudo systemctl status postgresql

# Connect to database
sudo -u postgres psql
psql -h localhost -U postgres -d postgres

# Connect via TLS (from remote)
psql 'host=postgres.arpansahu.space port=9552 user=postgres dbname=postgres sslmode=require'

# Create database
sudo -u postgres createdb myapp_db

# Backup database
sudo -u postgres pg_dump myapp_db > backup.sql

# Test connections
python3 test_postgres_localhost.py       # On server
PG_PASSWORD=password ./test_postgres_mac.sh           # From Mac (direct)
PG_PASSWORD=password ./test_postgres_domain_tls.sh    # From Mac (TLS)

# View logs
sudo journalctl -u postgresql -f
```

### Configuration Files

- **Main config:** `/etc/postgresql/*/main/postgresql.conf`
- **Auth config:** `/etc/postgresql/*/main/pg_hba.conf`
- **Data directory:** `/var/lib/postgresql/*/main/`
- **Log files:** `/var/log/postgresql/`

---

## PgAdmin Integration

Use PgAdmin for GUI management:
- URL: https://pgadmin.arpansahu.space
- Add server with: Host=192.168.1.200, Port=5432, User=postgres
- See [PgAdmin README](../Pgadmin/README.md) for details

---

## Architecture Diagram

```
[Your Application] ──────────────────────┐
       │                                 │
       │ Direct: Port 5432 (TCP)         │ TLS: Port 9552 (TCP)
       ↓                                 ↓
[PostgreSQL Server]            [Nginx Stream Proxy]
(Native system service)         (TLS Termination)
       ↓                                 │
[/var/lib/postgresql/data]               │
       ↑                                 │
       └─────────────────────────────────┘
                localhost:5432
```

**Access Methods:**
- **Local/Direct:** Connect directly to 192.168.1.200:5432 (no encryption)
- **Remote/TLS:** Connect via postgres.arpansahu.space:9552 (TLS encrypted via nginx)
- **No Proxy Layer:** Direct database access on port 5432
- **TLS Proxy:** Nginx stream proxies TLS connections to PostgreSQL
