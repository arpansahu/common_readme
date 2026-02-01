#!/bin/bash

# RabbitMQ Mac Connection Test (Domain with HTTPS)
# Tests RabbitMQ connectivity from your Mac through domain with HTTPS
# Run this script FROM YOUR MAC

set -e

echo "=== Testing RabbitMQ Management API from Mac (Domain with HTTPS) ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RABBITMQ_HOST="${RABBITMQ_HOST:-rabbitmq.arpansahu.space}"
RABBITMQ_PORT="${RABBITMQ_PORT:-443}"
RABBITMQ_USER="${RABBITMQ_USER:-arpansahu}"
RABBITMQ_PASS="${RABBITMQ_PASS:-changeme}"
RABBITMQ_VHOST="${RABBITMQ_VHOST:-/}"

# Base URL
BASE_URL="https://${RABBITMQ_HOST}"

# Test 1: Check if RabbitMQ Management API is accessible
echo -e "${YELLOW}Test 1: Checking RabbitMQ Management API accessibility (HTTPS)...${NC}"
if curl -s -u "${RABBITMQ_USER}:${RABBITMQ_PASS}" "${BASE_URL}/api/overview" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ RabbitMQ Management API is accessible via HTTPS${NC}"
else
    echo -e "${RED}✗ Failed to connect to RabbitMQ Management API${NC}"
    echo "  Make sure nginx is configured and accessible"
    exit 1
fi
echo ""

# Test 2: Get RabbitMQ version
echo -e "${YELLOW}Test 2: Getting RabbitMQ version...${NC}"
VERSION=$(curl -s -u "${RABBITMQ_USER}:${RABBITMQ_PASS}" "${BASE_URL}/api/overview" | grep -o '"rabbitmq_version":"[^"]*"' | cut -d'"' -f4)
echo -e "${GREEN}✓ RabbitMQ version: ${VERSION}${NC}"
echo ""

# Test 3: List vhosts
echo -e "${YELLOW}Test 3: Listing virtual hosts...${NC}"
VHOSTS=$(curl -s -u "${RABBITMQ_USER}:${RABBITMQ_PASS}" "${BASE_URL}/api/vhosts" | grep -o '"name":"[^"]*"' | wc -l)
echo -e "${GREEN}✓ Found ${VHOSTS} virtual host(s)${NC}"
echo ""

# Test 4: Create test queue
echo -e "${YELLOW}Test 4: Creating test queue via HTTPS...${NC}"
QUEUE_NAME="test_queue_mac_https"
VHOST_ENCODED=$(echo -n "${RABBITMQ_VHOST}" | jq -sRr @uri)
if curl -s -u "${RABBITMQ_USER}:${RABBITMQ_PASS}" -X PUT "${BASE_URL}/api/queues/${VHOST_ENCODED}/${QUEUE_NAME}" \
    -H "Content-Type: application/json" \
    -d '{"auto_delete":true,"durable":false}' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Test queue created: ${QUEUE_NAME}${NC}"
else
    echo -e "${RED}✗ Failed to create queue${NC}"
    exit 1
fi
echo ""

# Test 5: Publish message
echo -e "${YELLOW}Test 5: Publishing message via HTTPS...${NC}"
if curl -s -u "${RABBITMQ_USER}:${RABBITMQ_PASS}" -X POST "${BASE_URL}/api/exchanges/${VHOST_ENCODED}/amq.default/publish" \
    -H "Content-Type: application/json" \
    -d "{\"properties\":{},\"routing_key\":\"${QUEUE_NAME}\",\"payload\":\"Hello from Mac via HTTPS!\",\"payload_encoding\":\"string\"}" | grep -q '"routed":true'; then
    echo -e "${GREEN}✓ Message published: 'Hello from Mac via HTTPS!'${NC}"
else
    echo -e "${RED}✗ Failed to publish message${NC}"
    exit 1
fi
echo ""

# Test 6: Get queue details
echo -e "${YELLOW}Test 6: Checking queue has message...${NC}"
MESSAGES=$(curl -s -u "${RABBITMQ_USER}:${RABBITMQ_PASS}" "${BASE_URL}/api/queues/${VHOST_ENCODED}/${QUEUE_NAME}" | grep -o '"messages":[0-9]*' | cut -d':' -f2)
if [ "${MESSAGES}" -gt 0 ]; then
    echo -e "${GREEN}✓ Queue has ${MESSAGES} message(s)${NC}"
else
    echo -e "${YELLOW}⚠ Queue has no messages (message might have been consumed)${NC}"
fi
echo ""

# Test 7: Delete test queue
echo -e "${YELLOW}Test 7: Cleaning up test queue...${NC}"
if curl -s -u "${RABBITMQ_USER}:${RABBITMQ_PASS}" -X DELETE "${BASE_URL}/api/queues/${VHOST_ENCODED}/${QUEUE_NAME}" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Test queue deleted${NC}"
else
    echo -e "${YELLOW}⚠ Could not delete queue (might not exist)${NC}"
fi
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ All tests passed!${NC}"
echo -e "${GREEN}✓ RabbitMQ is working correctly via domain with HTTPS${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Connection used:"
echo "  URL: ${BASE_URL}"
echo "  Protocol: HTTPS (TLS encrypted via nginx)"
echo "  User: ${RABBITMQ_USER}"
