## PostgreSQL Server

It would be a nightmare to have your own VPS to save cost and not hosting your own PostgreSQL server. This guide explains how to set up a production-ready PostgreSQL server on an Ubuntu machine from scratch, accessible from the same server, local LAN, and public static IP (via router port forwarding). The setup focuses on simplicity, security, and long-term stability.

### Prerequisites

Before installing PostgreSQL, ensure you have:

1. Ubuntu / Debian server
2. Root or sudo access
3. Static public IP (if accessing from outside)
4. Router access for port forwarding configuration
5. Port 5432 available

### Installing PostgreSQL

1. Update the package list to make sure you have the latest information

    ```bash
    sudo apt update
    ```

2. Install the PostgreSQL package

    ```bash
    sudo apt install postgresql postgresql-contrib -y
    ```

3. PostgreSQL should now be installed on your server. By default, PostgreSQL creates a user named `postgres` with administrative privileges. You can switch to this user to perform administrative tasks:

    ```bash
    sudo -i -u postgres
    ```

4. Access the PostgreSQL interactive terminal by running:

    ```bash
    psql
    ```

### Enable Secure Password Authentication (SCRAM)

1. Enable modern password encryption

    ```sql
    ALTER SYSTEM SET password_encryption = 'scram-sha-256';
    SELECT pg_reload_conf();
    ```

2. Set a password for the `postgres` user

    ```sql
    ALTER USER postgres WITH PASSWORD 'STRONG_PASSWORD';
    ```

    Replace `STRONG_PASSWORD` with a strong password.

3. Verify encryption

    ```sql
    SELECT usename, passwd FROM pg_shadow;
    ```

    Passwords should start with: `SCRAM-SHA-256$`

4. Exit the PostgreSQL shell

    ```sql
    \q
    ```

5. Exit the `postgres` user session

    ```bash
    exit
    ```

Now, PostgreSQL is installed on your Ubuntu server. You can access the PostgreSQL database by logging in with the `postgres` user and the password you set.

Remember to configure your PostgreSQL server according to your security needs, such as modifying the `pg_hba.conf` file to control access, setting up SSL for secure connections, and configuring other PostgreSQL settings as required for your environment.

### PostgreSQL Core Configuration

1. Open postgresql.conf file

    ```bash
    sudo nano /etc/postgresql/16/main/postgresql.conf
    ```

    Note: 16 is the version which I have installed, your version can be different. Check your version with:

    ```bash
    psql --version
    ```

2. Find and configure the following settings

    ```conf
    listen_addresses = '*'
    port = 5432
    ssl = on
    ```

    This allows PostgreSQL to accept connections from:
    - localhost
    - LAN
    - public IP

3. Save and close the file

### Client Authentication Configuration

1. Edit pg_hba.conf to allow connections

    ```bash
    sudo nano /etc/postgresql/16/main/pg_hba.conf
    ```

    Note: 16 is the version which I have installed, your version can be different.

2. Add or modify the following lines (Recommended configuration)

    ```conf
    # Unix socket
    local   all             all                                     peer

    # Localhost
    host    all             all             127.0.0.1/32            scram-sha-256

    # LAN access
    host    all             all             192.168.1.0/24          scram-sha-256

    # Public access (restrict if possible)
    host    all             all             0.0.0.0/0               scram-sha-256
    ```

    Explanation:
    - First line: Local Unix socket connections
    - Second line: Localhost connections using SCRAM authentication
    - Third line: Local network (192.168.1.x) connections
    - Fourth line: Public access from any IP (use with caution)

3. Save and close the file

4. Reload PostgreSQL to apply changes

    ```bash
    sudo systemctl reload postgresql
    ```

### Creating Application Database User

Do not use the `postgres` user for applications. Create a dedicated user:

1. Switch to postgres user and open psql

    ```bash
    sudo -u postgres psql
    ```

2. Create a new user

    ```sql
    CREATE USER app_user WITH PASSWORD 'VERY_STRONG_PASSWORD';
    ```

    Replace `app_user` with your desired username and `VERY_STRONG_PASSWORD` with a strong password.

3. Create a database (optional)

    ```sql
    CREATE DATABASE your_database;
    ```

4. Grant privileges to the user

    ```sql
    GRANT ALL PRIVILEGES ON DATABASE your_database TO app_user;
    ```

5. Exit PostgreSQL shell

    ```sql
    \q
    ```

### Firewall Configuration

If using UFW firewall, allow the PostgreSQL port:

1. Allow PostgreSQL port

    ```bash
    sudo ufw allow 5432/tcp
    ```

2. Reload firewall

    ```bash
    sudo ufw reload
    ```

3. Verify firewall status

    ```bash
    sudo ufw status
    ```

### Router Configuration (Port Forwarding)

For external access via public IP, configure port forwarding on your router:

Create a single port-forward rule on your router:

| Setting       | Value                              |
| ------------- | ---------------------------------- |
| Protocol      | TCP                                |
| External Port | 5432                               |
| Internal Port | 5432                               |
| Internal IP   | Server LAN IP (e.g. 192.168.1.200) |
| Enable        | Yes                                |

This allows external access using your static public IP.

Note: Router configuration varies by manufacturer. Consult your router's manual for specific instructions.

### Verification and Testing

1. Check PostgreSQL is listening

    ```bash
    sudo ss -lntp | grep 5432
    ```

    Expected output:
    ```
    0.0.0.0:5432
    ```

2. Test connection on the server

    ```bash
    psql -h 127.0.0.1 -p 5432 -U app_user your_database
    ```

3. Test connection from LAN

    From another machine on the same network:

    ```bash
    psql -h 192.168.1.200 -p 5432 -U app_user your_database
    ```

    Replace `192.168.1.200` with your server's LAN IP.

4. Test connection from public network

    From outside your network:

    ```bash
    psql -h <STATIC_PUBLIC_IP> -p 5432 -U app_user your_database
    ```

    Replace `<STATIC_PUBLIC_IP>` with your actual public IP address.

5. Test connection with SSL requirement

    ```bash
    psql "postgresql://app_user:password@your-server-ip:5432/your_database?sslmode=require"
    ```

### Managing PostgreSQL Service

1. Start PostgreSQL

    ```bash
    sudo systemctl start postgresql
    ```

2. Stop PostgreSQL

    ```bash
    sudo systemctl stop postgresql
    ```

3. Restart PostgreSQL

    ```bash
    sudo systemctl restart postgresql
    ```

4. Reload configuration

    ```bash
    sudo systemctl reload postgresql
    ```

5. Check status

    ```bash
    sudo systemctl status postgresql
    ```

6. Enable auto-start on boot

    ```bash
    sudo systemctl enable postgresql
    ```

### Common PostgreSQL Commands

1. List all databases

    ```sql
    \l
    ```

2. Connect to a database

    ```sql
    \c database_name
    ```

3. List all tables

    ```sql
    \dt
    ```

4. List all users

    ```sql
    \du
    ```

5. Show current user

    ```sql
    SELECT current_user;
    ```

6. Exit psql

    ```sql
    \q
    ```

### Security Best Practices

Important security considerations for this setup:

1. Use strong passwords for all database users
2. Use non-superuser accounts for applications
3. Prefer SCRAM-SHA-256 authentication over MD5
4. Restrict source IPs in router firewall if possible
5. Always connect with SSL requirement:

    ```bash
    sslmode=require
    ```

6. Regularly update PostgreSQL to the latest security patches
7. Monitor PostgreSQL logs for suspicious activity
8. Use different passwords for different environments
9. Backup your databases regularly
10. Limit the number of users with SUPERUSER privilege

### Debugging Common Issues

1. Connection Refused Error

    Cause: PostgreSQL service not running or firewall blocking

    Fix:

    ```bash
    sudo systemctl status postgresql
    sudo systemctl start postgresql
    sudo ufw status
    ```

2. Authentication Failed Error

    Cause: Wrong password or pg_hba.conf misconfigured

    Fix:

    ```bash
    sudo nano /etc/postgresql/16/main/pg_hba.conf
    # Verify authentication method is correct
    sudo systemctl reload postgresql
    ```

3. Cannot Connect from Remote Host

    Cause: listen_addresses not set to '*' or firewall blocking

    Fix:

    ```bash
    sudo nano /etc/postgresql/16/main/postgresql.conf
    # Set listen_addresses = '*'
    sudo systemctl restart postgresql
    sudo ufw allow 5432/tcp
    ```

4. SSL Connection Error

    Cause: SSL not enabled or certificates missing

    Fix:

    ```bash
    sudo nano /etc/postgresql/16/main/postgresql.conf
    # Set ssl = on
    sudo systemctl restart postgresql
    ```

5. Port Already in Use

    Cause: Another service using port 5432

    Fix:

    ```bash
    sudo netstat -tulnp | grep 5432
    # Stop conflicting service or change PostgreSQL port
    ```

### Connection String Examples

1. Basic connection

    ```bash
    psql -h hostname -p 5432 -U username -d database_name
    ```

2. Connection with SSL

    ```bash
    psql "postgresql://username:password@hostname:5432/database_name?sslmode=require"
    ```

3. Connection from Django

    ```python
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': 'your_database',
            'USER': 'app_user',
            'PASSWORD': 'your_password',
            'HOST': 'your-server-ip',
            'PORT': '5432',
            'OPTIONS': {
                'sslmode': 'require',
            },
        }
    }
    ```

4. Connection from Python (psycopg2)

    ```python
    import psycopg2

    conn = psycopg2.connect(
        host="your-server-ip",
        port="5432",
        database="your_database",
        user="app_user",
        password="your_password",
        sslmode="require"
    )
    ```

5. Connection from Node.js

    ```javascript
    const { Client } = require('pg');

    const client = new Client({
      host: 'your-server-ip',
      port: 5432,
      database: 'your_database',
      user: 'app_user',
      password: 'your_password',
      ssl: { rejectUnauthorized: false }
    });
    ```

### Final Outcome

After following this guide, you will have:

1. PostgreSQL securely hosted on your own server
2. Accessible locally, on LAN, and via public IP
3. Modern SCRAM-SHA-256 password encryption
4. SSL-enabled connections
5. Proper firewall configuration
6. Router port forwarding configured
7. Application-specific database users
8. Simple configuration that's easy to debug and maintain
9. Ready for Docker, Kubernetes, or future scaling

### Example Access Details

| Item                | Value                                         |
| ------------------- | --------------------------------------------- |
| Database Host       | your-server-ip or domain                      |
| Port                | 5432                                          |
| Database Name       | your_database                                 |
| Username            | app_user                                      |
| Password            | your_password                                 |
| SSL Mode            | require                                       |
| Connection String   | postgresql://app_user:password@host:5432/db   |

PostgreSQL server can be accessed at: your-server-ip:5432 or domain:5432
