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
