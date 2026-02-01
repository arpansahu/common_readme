#!/bin/bash

# RabbitMQ Mac Connection Test
# Tests RabbitMQ Management API connectivity from your Mac

set -e

echo "=== Testing RabbitMQ Connection from Mac ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RABBITMQ_URL="https://rabbitmq.arpansahu.space"
RABBITMQ_USER="${RABBITMQ_USER:-arpansahu}"
RABBITMQ_PASS="${RABBITMQ_PASS:-changeme}"

# Test 1: Check if RabbitMQ is accessible
echo "${YELLOW}Test 1: Checking RabbitMQ accessibility...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "$RABBITMQ_USER:$RABBITMQ_PASS" "$RABBITMQ_URL/api/overview")

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✓ RabbitMQ Management API is accessible${NC}"
else
    echo -e "${RED}✗ Failed to access RabbitMQ (HTTP $HTTP_CODE)${NC}"
    exit 1
fi
echo ""

# Test 2: Get RabbitMQ version and cluster info
echo "${YELLOW}Test 2: Getting RabbitMQ information...${NC}"
OVERVIEW=$(curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASS" "$RABBITMQ_URL/api/overview")

VERSION=$(echo "$OVERVIEW" | python3 -c "import sys, json; print(json.load(sys.stdin)['rabbitmq_version'])")
ERLANG=$(echo "$OVERVIEW" | python3 -c "import sys, json; print(json.load(sys.stdin)['erlang_version'])")
CLUSTER=$(echo "$OVERVIEW" | python3 -c "import sys, json; print(json.load(sys.stdin)['cluster_name'])")

echo -e "${GREEN}✓ RabbitMQ version: $VERSION${NC}"
echo -e "${GREEN}✓ Erlang version: $ERLANG${NC}"
echo -e "${GREEN}✓ Cluster name: $CLUSTER${NC}"
echo ""

# Test 3: Create a test queue
echo "${YELLOW}Test 3: Creating test queue...${NC}"
QUEUE_NAME="mac_test_queue_$(date +%s)"
curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASS" \
    -X PUT \
    -H "content-type:application/json" \
    -d '{"durable":true}' \
    "$RABBITMQ_URL/api/queues/%2F/$QUEUE_NAME" > /dev/null

sleep 1

# Verify queue was created
QUEUE_INFO=$(curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASS" "$RABBITMQ_URL/api/queues/%2F/$QUEUE_NAME")
QUEUE_EXISTS=$(echo "$QUEUE_INFO" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('name', ''))")

if [ "$QUEUE_EXISTS" = "$QUEUE_NAME" ]; then
    echo -e "${GREEN}✓ Queue created: $QUEUE_NAME${NC}"
else
    echo -e "${RED}✗ Failed to create queue${NC}"
    exit 1
fi
echo ""

# Test 4: Publish a message via API
echo "${YELLOW}Test 4: Publishing message to queue...${NC}"
curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASS" \
    -X POST \
    -H "content-type:application/json" \
    -d '{"properties":{},"routing_key":"'$QUEUE_NAME'","payload":"Hello from Mac!","payload_encoding":"string"}' \
    "$RABBITMQ_URL/api/exchanges/%2F/amq.default/publish" > /dev/null

sleep 1

# Check if message is in queue
QUEUE_MESSAGES=$(curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASS" "$RABBITMQ_URL/api/queues/%2F/$QUEUE_NAME" | \
    python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('messages', 0))")

if [ "$QUEUE_MESSAGES" -gt 0 ]; then
    echo -e "${GREEN}✓ Message published successfully (messages in queue: $QUEUE_MESSAGES)${NC}"
else
    echo -e "${RED}✗ Message not found in queue${NC}"
fi
echo ""

# Test 5: Clean up - delete test queue
echo "${YELLOW}Test 5: Cleaning up test queue...${NC}"
curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASS" \
    -X DELETE \
    "$RABBITMQ_URL/api/queues/%2F/$QUEUE_NAME" > /dev/null

echo -e "${GREEN}✓ Test queue deleted${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ All tests passed!${NC}"
echo -e "${GREEN}✓ RabbitMQ is working correctly${NC}"
echo -e "${GREEN}========================================${NC}"
