#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo -e "${GREEN}✓ Loaded environment variables from .env${NC}"
else
    echo -e "${RED}✗ .env file not found${NC}"
    exit 1
fi

echo ""
echo "=== Elasticsearch & Kibana Installation Script ==="
echo "This will install:"
echo "1. Elasticsearch (Docker container)"
echo "2. Kibana (Docker container)"
echo "3. Configure Nginx reverse proxy"
echo ""

# Validate required variables
required_vars=("ELASTIC_PASSWORD" "KIBANA_PASSWORD" "ELASTICSEARCH_DOMAIN" "KIBANA_DOMAIN")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}✗ Required variable $var is not set in .env${NC}"
        exit 1
    fi
done

echo ""
echo "=== Step 1: Creating Docker Network ==="

# Create dedicated network for Elasticsearch
if ! docker network inspect elastic >/dev/null 2>&1; then
    docker network create elastic
    echo -e "${GREEN}✓ Docker network 'elastic' created${NC}"
else
    echo -e "${YELLOW}! Docker network 'elastic' already exists${NC}"
fi

echo ""
echo "=== Step 2: Installing Elasticsearch ==="

# Create data directories
mkdir -p ~/elasticsearch-data
mkdir -p ~/elasticsearch-logs

# Pull and run Elasticsearch
docker pull docker.elastic.co/elasticsearch/elasticsearch:8.12.0
docker create \
    --name elasticsearch \
    --network elastic \
    --restart always \
    -p 9200:9200 \
    -p 9300:9300 \
    -e "discovery.type=single-node" \
    -e "ELASTIC_PASSWORD=${ELASTIC_PASSWORD}" \
    -e "xpack.security.enabled=true" \
    -e "xpack.security.http.ssl.enabled=false" \
    -e "xpack.security.transport.ssl.enabled=false" \
    -e "cluster.name=${CLUSTER_NAME:-elasticsearch-cluster}" \
    -e "node.name=${NODE_NAME:-node-1}" \
    -v ~/elasticsearch-data:/usr/share/elasticsearch/data \
    -v ~/elasticsearch-logs:/usr/share/elasticsearch/logs \
    docker.elastic.co/elasticsearch/elasticsearch:8.12.0

docker start elasticsearch

echo -e "${GREEN}✓ Elasticsearch container created and started${NC}"
echo "Waiting for Elasticsearch to initialize (60 seconds)..."
sleep 60

# Verify Elasticsearch is running
if curl -s -u "elastic:${ELASTIC_PASSWORD}" http://localhost:9200 >/dev/null; then
    echo -e "${GREEN}✓ Elasticsearch is running and accessible${NC}"
else
    echo -e "${RED}✗ Elasticsearch is not responding${NC}"
    echo "Check logs with: docker logs elasticsearch"
    exit 1
fi

echo ""
echo "=== Step 3: Installing Kibana ==="

# Pull and run Kibana
docker pull docker.elastic.co/kibana/kibana:8.12.0
docker create \
    --name kibana \
    --network elastic \
    --restart always \
    -p 5601:5601 \
    -e "ELASTICSEARCH_HOSTS=http://elasticsearch:9200" \
    -e "ELASTICSEARCH_USERNAME=kibana_system" \
    -e "ELASTICSEARCH_PASSWORD=${KIBANA_PASSWORD}" \
    docker.elastic.co/kibana/kibana:8.12.0

# Set kibana_system user password in Elasticsearch
echo "Setting Kibana system user password..."
docker exec elasticsearch /usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system -b -s <<< "${KIBANA_PASSWORD}" >/dev/null 2>&1 || \
curl -s -X POST -u "elastic:${ELASTIC_PASSWORD}" \
    "http://localhost:9200/_security/user/kibana_system/_password" \
    -H "Content-Type: application/json" \
    -d "{\"password\":\"${KIBANA_PASSWORD}\"}" >/dev/null

docker start kibana

echo -e "${GREEN}✓ Kibana container created and started${NC}"
echo "Waiting for Kibana to initialize (45 seconds)..."
sleep 45

echo ""
echo "=== Step 4: Setting up Nginx Reverse Proxy ==="

# Create Elasticsearch Nginx configuration
cat > /tmp/elasticsearch-nginx << 'NGINX_EOF'
server {
    listen 443 ssl http2;
    server_name ELASTICSEARCH_DOMAIN_PLACEHOLDER;

    # SSL configuration will be handled by certbot
    
    location / {
        proxy_pass http://127.0.0.1:9200;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
NGINX_EOF

# Replace placeholder with actual domain
sed -i "s/ELASTICSEARCH_DOMAIN_PLACEHOLDER/${ELASTICSEARCH_DOMAIN}/g" /tmp/elasticsearch-nginx
sudo mv /tmp/elasticsearch-nginx /etc/nginx/sites-available/elasticsearch
sudo ln -sf /etc/nginx/sites-available/elasticsearch /etc/nginx/sites-enabled/

# Create Kibana Nginx configuration
cat > /tmp/kibana-nginx << 'NGINX_EOF'
server {
    listen 443 ssl http2;
    server_name KIBANA_DOMAIN_PLACEHOLDER;

    # SSL configuration will be handled by certbot
    
    location / {
        proxy_pass http://127.0.0.1:5601;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
NGINX_EOF

# Replace placeholder with actual domain
sed -i "s/KIBANA_DOMAIN_PLACEHOLDER/${KIBANA_DOMAIN}/g" /tmp/kibana-nginx
sudo mv /tmp/kibana-nginx /etc/nginx/sites-available/kibana
sudo ln -sf /etc/nginx/sites-available/kibana /etc/nginx/sites-enabled/

# Test nginx configuration
sudo nginx -t

if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    echo -e "${GREEN}✓ Nginx configuration created and enabled${NC}"
else
    echo -e "${RED}✗ Nginx configuration test failed${NC}"
    exit 1
fi

echo ""
echo "=== Step 5: Obtaining SSL Certificates ==="
echo ""
echo "Run these commands to obtain SSL certificates:"
echo ""
echo -e "${YELLOW}sudo certbot --nginx -d ${ELASTICSEARCH_DOMAIN}${NC}"
echo -e "${YELLOW}sudo certbot --nginx -d ${KIBANA_DOMAIN}${NC}"
echo ""

echo ""
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo ""
echo "Elasticsearch is now accessible at:"
echo "  http://localhost:9200"
echo "  https://${ELASTICSEARCH_DOMAIN}/ (after SSL setup)"
echo ""
echo "Kibana is now accessible at:"
echo "  http://localhost:5601"
echo "  https://${KIBANA_DOMAIN}/ (after SSL setup)"
echo ""
echo "Login credentials:"
echo "  Elasticsearch Username: elastic"
echo "  Elasticsearch Password: ${ELASTIC_PASSWORD}"
echo "  Kibana Username: elastic"
echo "  Kibana Password: ${ELASTIC_PASSWORD}"
echo ""
echo "Useful commands:"
echo "  docker logs elasticsearch         # View Elasticsearch logs"
echo "  docker logs kibana                # View Kibana logs"
echo "  docker restart elasticsearch      # Restart Elasticsearch"
echo "  docker restart kibana             # Restart Kibana"
echo "  curl -u elastic:password http://localhost:9200/_cluster/health  # Check cluster health"
echo ""
