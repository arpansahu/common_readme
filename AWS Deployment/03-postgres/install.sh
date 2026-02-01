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
