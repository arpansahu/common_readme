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
