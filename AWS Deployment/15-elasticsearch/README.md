# Elasticsearch & Kibana Setup Guide

Complete guide for installing and configuring Elasticsearch and Kibana for log management, search, and analytics.

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Integration](#integration)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)

## Overview

### What is Elasticsearch?
Elasticsearch is a distributed, RESTful search and analytics engine built on Apache Lucene. It provides:
- Full-text search capabilities
- Real-time data indexing
- Distributed architecture
- RESTful API
- Document-oriented storage

### What is Kibana?
Kibana is the visualization layer for Elasticsearch, providing:
- Interactive dashboards
- Data visualization tools
- Query interface
- Index management
- Security configuration

### Use Cases
- **Application Logs**: Centralized logging with structured search
- **Metrics & Monitoring**: Time-series data analysis
- **Full-Text Search**: Product catalogs, documentation search
- **Security Analytics**: SIEM (Security Information and Event Management)
- **Business Analytics**: Customer behavior, sales trends

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        User Requests                         │
└────────────────────┬────────────────────┬───────────────────┘
                     │                    │
                     ▼                    ▼
        ┌────────────────────┐  ┌────────────────────┐
        │  Nginx (SSL/443)   │  │  Nginx (SSL/443)   │
        │ elasticsearch.*    │  │    kibana.*        │
        └──────────┬─────────┘  └─────────┬──────────┘
                   │                       │
                   ▼                       ▼
        ┌────────────────────┐  ┌────────────────────┐
        │  Elasticsearch     │◄─┤     Kibana         │
        │   (Port 9200)      │  │   (Port 5601)      │
        │   Docker Container │  │  Docker Container  │
        └──────────┬─────────┘  └────────────────────┘
                   │
                   ▼
        ┌────────────────────────────────────┐
        │    Persistent Data Storage         │
        │  ~/elasticsearch-data/             │
        │  ~/elasticsearch-logs/             │
        └────────────────────────────────────┘
```

### Components

1. **Elasticsearch Container**
   - Version: 8.12.0
   - Port: 9200 (HTTP API), 9300 (Node communication)
   - Single-node cluster mode
   - X-Pack security enabled

2. **Kibana Container**
   - Version: 8.12.0
   - Port: 5601 (Web UI)
   - Connected to Elasticsearch via Docker network

3. **Nginx Reverse Proxy**
   - SSL termination with Let's Encrypt
   - Routes external traffic to containers
   - Two domains: elasticsearch.* and kibana.*

## Prerequisites

### System Requirements
- **RAM**: Minimum 4GB (8GB+ recommended)
- **Disk Space**: 20GB+ free space
- **CPU**: 2+ cores recommended
- **OS**: Ubuntu 20.04+ or similar Linux distribution

### Required Software
```bash
# Docker
docker --version  # Should be 20.10+

# Nginx
nginx -v  # Should be 1.18+

# Certbot (for SSL)
certbot --version  # Should be 1.0+
```

### System Configuration
```bash
# Increase virtual memory for Elasticsearch
sudo sysctl -w vm.max_map_count=262144

# Make it permanent
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

## Installation

### Quick Install

1. **Clone/Download the setup files**
   ```bash
   # Files should be in AWS Deployment/15-elasticsearch/
   cd AWS\ Deployment/15-elasticsearch/
   ```

2. **Configure environment variables**
   ```bash
   cp .env.example .env
   nano .env
   ```

   Update these values:
   ```bash
   ELASTIC_PASSWORD=your_secure_password
   KIBANA_PASSWORD=your_kibana_password
   ELASTICSEARCH_DOMAIN=elasticsearch.yourdomain.com
   KIBANA_DOMAIN=kibana.yourdomain.com
   CLUSTER_NAME=my-cluster
   NODE_NAME=node-1
   ```

3. **Run the installation script**
   ```bash
   ./install.sh
   ```

4. **Obtain SSL certificates**
   ```bash
   sudo certbot --nginx -d elasticsearch.yourdomain.com
   sudo certbot --nginx -d kibana.yourdomain.com
   ```

### Manual Installation

If you prefer step-by-step installation:

#### Step 1: Create Docker Network
```bash
docker network create elastic
```

#### Step 2: Install Elasticsearch
```bash
# Create data directories
mkdir -p ~/elasticsearch-data ~/elasticsearch-logs

# Run Elasticsearch
docker run -d \
  --name elasticsearch \
  --network elastic \
  --restart always \
  -p 9200:9200 \
  -p 9300:9300 \
  -e "discovery.type=single-node" \
  -e "ELASTIC_PASSWORD=your_password" \
  -e "xpack.security.enabled=true" \
  -e "xpack.security.http.ssl.enabled=false" \
  -v ~/elasticsearch-data:/usr/share/elasticsearch/data \
  -v ~/elasticsearch-logs:/usr/share/elasticsearch/logs \
  docker.elastic.co/elasticsearch/elasticsearch:8.12.0
```

#### Step 3: Verify Elasticsearch
```bash
curl -u elastic:your_password http://localhost:9200
```

Expected response:
```json
{
  "name" : "node-1",
  "cluster_name" : "elasticsearch-cluster",
  "version" : {
    "number" : "8.12.0",
    ...
  },
  "tagline" : "You Know, for Search"
}
```

#### Step 4: Install Kibana
```bash
# Set Kibana user password
curl -X POST -u elastic:your_password \
  http://localhost:9200/_security/user/kibana_system/_password \
  -H "Content-Type: application/json" \
  -d '{"password":"kibana_password"}'

# Run Kibana
docker run -d \
  --name kibana \
  --network elastic \
  --restart always \
  -p 5601:5601 \
  -e "ELASTICSEARCH_HOSTS=http://elasticsearch:9200" \
  -e "ELASTICSEARCH_USERNAME=kibana_system" \
  -e "ELASTICSEARCH_PASSWORD=kibana_password" \
  docker.elastic.co/kibana/kibana:8.12.0
```

## Configuration

### Elasticsearch Configuration

#### Index Settings
```bash
# Create an index with custom settings
curl -X PUT -u elastic:password "http://localhost:9200/my-index" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "index.max_result_window": 10000
    }
  }'
```

#### Index Templates
```bash
# Create a template for log indices
curl -X PUT -u elastic:password "http://localhost:9200/_index_template/logs-template" \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["logs-*"],
    "template": {
      "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0
      },
      "mappings": {
        "properties": {
          "timestamp": {"type": "date"},
          "level": {"type": "keyword"},
          "message": {"type": "text"},
          "service": {"type": "keyword"}
        }
      }
    }
  }'
```

#### User Management
```bash
# Create a new user
curl -X POST -u elastic:password "http://localhost:9200/_security/user/myapp" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "myapp_password",
    "roles": ["kibana_admin", "index_user"],
    "full_name": "MyApp User"
  }'

# Create a custom role
curl -X POST -u elastic:password "http://localhost:9200/_security/role/logs_reader" \
  -H "Content-Type: application/json" \
  -d '{
    "cluster": ["monitor"],
    "indices": [{
      "names": ["logs-*"],
      "privileges": ["read", "view_index_metadata"]
    }]
  }'
```

### Kibana Configuration

#### Access Kibana
1. Open https://kibana.yourdomain.com/
2. Login with:
   - Username: `elastic`
   - Password: `your_elastic_password`

#### Create Index Patterns
1. Navigate to **Stack Management** → **Index Patterns**
2. Click **Create index pattern**
3. Enter pattern: `logs-*`
4. Select time field: `timestamp`
5. Click **Create index pattern**

#### Create Visualizations
1. Go to **Visualize Library** → **Create visualization**
2. Choose visualization type (Line chart, Bar chart, Pie chart, etc.)
3. Select index pattern
4. Configure metrics and aggregations
5. Save visualization

#### Build Dashboards
1. Navigate to **Dashboard** → **Create dashboard**
2. Click **Add** to add visualizations
3. Arrange and resize panels
4. Configure filters and time range
5. Save dashboard

## Usage

### Index Data

#### Index a Single Document
```bash
curl -X POST -u elastic:password "http://localhost:9200/logs-app/_doc" \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "2026-02-07T10:30:00",
    "level": "INFO",
    "service": "api-server",
    "message": "Request processed successfully",
    "response_time": 125
  }'
```

#### Bulk Index Documents
```bash
curl -X POST -u elastic:password "http://localhost:9200/_bulk" \
  -H "Content-Type: application/x-ndjson" \
  --data-binary @bulk-data.ndjson
```

bulk-data.ndjson:
```json
{"index":{"_index":"logs-app"}}
{"timestamp":"2026-02-07T10:00:00","level":"INFO","message":"Server started"}
{"index":{"_index":"logs-app"}}
{"timestamp":"2026-02-07T10:01:00","level":"ERROR","message":"Connection failed"}
```

### Search Data

#### Simple Search
```bash
curl -X GET -u elastic:password "http://localhost:9200/logs-app/_search?q=level:ERROR"
```

#### Query DSL
```bash
curl -X GET -u elastic:password "http://localhost:9200/logs-app/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "bool": {
        "must": [
          {"match": {"level": "ERROR"}},
          {"range": {"timestamp": {"gte": "now-1h"}}}
        ]
      }
    },
    "size": 100,
    "sort": [{"timestamp": "desc"}]
  }'
```

#### Aggregations
```bash
curl -X GET -u elastic:password "http://localhost:9200/logs-app/_search" \
  -H "Content-Type: application/json" \
  -d '{
    "size": 0,
    "aggs": {
      "error_count_by_service": {
        "terms": {"field": "service"},
        "aggs": {
          "errors": {
            "filter": {"term": {"level": "ERROR"}}
          }
        }
      }
    }
  }'
```

### Cluster Management

#### Check Cluster Health
```bash
curl -u elastic:password "http://localhost:9200/_cluster/health?pretty"
```

#### View Node Stats
```bash
curl -u elastic:password "http://localhost:9200/_nodes/stats?pretty"
```

#### List Indices
```bash
curl -u elastic:password "http://localhost:9200/_cat/indices?v"
```

#### Delete Old Indices
```bash
# Delete indices older than 30 days
curl -X DELETE -u elastic:password "http://localhost:9200/logs-*-2026.01.*"
```

## Integration

### Python Integration

```python
from elasticsearch import Elasticsearch

# Connect to Elasticsearch
es = Elasticsearch(
    ['https://elasticsearch.yourdomain.com'],
    basic_auth=('elastic', 'your_password'),
    verify_certs=True
)

# Index a document
doc = {
    'timestamp': '2026-02-07T10:00:00',
    'level': 'INFO',
    'message': 'Application started',
    'service': 'python-app'
}
es.index(index='logs-python', document=doc)

# Search documents
response = es.search(
    index='logs-python',
    query={'match': {'level': 'ERROR'}},
    size=10
)

for hit in response['hits']['hits']:
    print(hit['_source'])
```

### Django Integration

```python
# settings.py
LOGGING = {
    'version': 1,
    'handlers': {
        'elasticsearch': {
            'level': 'INFO',
            'class': 'cmreslogging.handlers.CMRESHandler',
            'hosts': [{'host': 'elasticsearch.yourdomain.com', 'port': 443}],
            'auth_type': 'BASIC_AUTH',
            'auth_details': ('elastic', 'your_password'),
            'es_index_name': 'django-logs',
            'use_ssl': True,
        },
    },
    'loggers': {
        'django': {
            'handlers': ['elasticsearch'],
            'level': 'INFO',
        },
    },
}
```

### Filebeat Integration

```yaml
# filebeat.yml
filebeat.inputs:
  - type: log
    paths:
      - /var/log/nginx/*.log
    fields:
      service: nginx

output.elasticsearch:
  hosts: ["https://elasticsearch.yourdomain.com:443"]
  username: "elastic"
  password: "your_password"
  index: "filebeat-%{+yyyy.MM.dd}"

setup.kibana:
  host: "https://kibana.yourdomain.com"
```

### Logstash Integration

```conf
# logstash.conf
input {
  file {
    path => "/var/log/app/*.log"
    start_position => "beginning"
  }
}

filter {
  grok {
    match => { "message" => "%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:message}" }
  }
  date {
    match => ["timestamp", "ISO8601"]
  }
}

output {
  elasticsearch {
    hosts => ["https://elasticsearch.yourdomain.com:443"]
    user => "elastic"
    password => "your_password"
    index => "logstash-%{+YYYY.MM.dd}"
  }
}
```

## Maintenance

### Backup and Restore

#### Create Snapshot Repository
```bash
curl -X PUT -u elastic:password "http://localhost:9200/_snapshot/my_backup" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "fs",
    "settings": {
      "location": "/usr/share/elasticsearch/backup"
    }
  }'
```

#### Take Snapshot
```bash
curl -X PUT -u elastic:password "http://localhost:9200/_snapshot/my_backup/snapshot_1?wait_for_completion=true"
```

#### Restore Snapshot
```bash
curl -X POST -u elastic:password "http://localhost:9200/_snapshot/my_backup/snapshot_1/_restore"
```

### Index Lifecycle Management

#### Create ILM Policy
```bash
curl -X PUT -u elastic:password "http://localhost:9200/_ilm/policy/logs_policy" \
  -H "Content-Type: application/json" \
  -d '{
    "policy": {
      "phases": {
        "hot": {
          "actions": {
            "rollover": {
              "max_size": "50GB",
              "max_age": "7d"
            }
          }
        },
        "delete": {
          "min_age": "30d",
          "actions": {
            "delete": {}
          }
        }
      }
    }
  }'
```

### Monitoring

#### Key Metrics to Monitor
- **JVM Heap Usage**: Should stay below 75%
- **Disk Usage**: Keep below 85% to avoid read-only indices
- **Query Performance**: Monitor slow queries
- **Indexing Rate**: Documents per second
- **Node Status**: All nodes should be green

#### Check JVM Heap
```bash
curl -u elastic:password "http://localhost:9200/_nodes/stats/jvm?pretty"
```

#### Monitor Slow Queries
```bash
curl -X PUT -u elastic:password "http://localhost:9200/logs-*/_settings" \
  -H "Content-Type: application/json" \
  -d '{
    "index.search.slowlog.threshold.query.warn": "5s",
    "index.search.slowlog.threshold.fetch.warn": "1s"
  }'
```

### Updates

#### Update Elasticsearch
```bash
# Backup first!
curl -X PUT -u elastic:password "http://localhost:9200/_snapshot/my_backup/pre_update_snapshot?wait_for_completion=true"

# Pull new image
docker pull docker.elastic.co/elasticsearch/elasticsearch:8.13.0

# Stop and remove old container
docker stop elasticsearch
docker rm elasticsearch

# Create new container with same volumes
docker run -d \
  --name elasticsearch \
  --network elastic \
  --restart always \
  -p 9200:9200 \
  -p 9300:9300 \
  -e "discovery.type=single-node" \
  -e "ELASTIC_PASSWORD=your_password" \
  -v ~/elasticsearch-data:/usr/share/elasticsearch/data \
  docker.elastic.co/elasticsearch/elasticsearch:8.13.0
```

## Troubleshooting

### Common Issues

#### Elasticsearch Won't Start

**Symptom**: Container exits immediately

**Solutions**:
```bash
# Check logs
docker logs elasticsearch

# Check virtual memory setting
sysctl vm.max_map_count
# Should be 262144 or higher

# Check disk space
df -h ~/elasticsearch-data

# Check file permissions
ls -la ~/elasticsearch-data
```

#### Out of Memory

**Symptom**: Elasticsearch becomes unresponsive

**Solutions**:
```bash
# Check JVM heap usage
curl -u elastic:password "http://localhost:9200/_nodes/stats/jvm?pretty"

# Adjust heap size (recreate container with -e settings)
docker stop elasticsearch
docker rm elasticsearch
docker run -d \
  --name elasticsearch \
  -e "ES_JAVA_OPTS=-Xms2g -Xmx2g" \
  ... # other options
```

#### Disk Full

**Symptom**: Indices become read-only

**Solutions**:
```bash
# Check disk usage
df -h ~/elasticsearch-data

# Delete old indices
curl -X DELETE -u elastic:password "http://localhost:9200/old-index-*"

# Re-enable write on indices
curl -X PUT -u elastic:password "http://localhost:9200/_all/_settings" \
  -H "Content-Type: application/json" \
  -d '{"index.blocks.read_only_allow_delete": null}'
```

#### Kibana Can't Connect

**Symptom**: Kibana shows "Elasticsearch cluster is not ready"

**Solutions**:
```bash
# Check if Elasticsearch is accessible from Kibana container
docker exec kibana curl -u kibana_system:password http://elasticsearch:9200

# Verify Kibana user password
curl -X POST -u elastic:password "http://localhost:9200/_security/user/kibana_system/_password" \
  -H "Content-Type: application/json" \
  -d '{"password":"new_password"}'

# Restart Kibana
docker restart kibana
```

#### Slow Query Performance

**Symptom**: Queries take too long

**Solutions**:
```bash
# Check cluster health
curl -u elastic:password "http://localhost:9200/_cluster/health?pretty"

# Optimize indices
curl -X POST -u elastic:password "http://localhost:9200/logs-*/_forcemerge?max_num_segments=1"

# Review index mappings (avoid wildcard queries on large text fields)
curl -u elastic:password "http://localhost:9200/my-index/_mapping?pretty"
```

### Diagnostic Commands

```bash
# Check Elasticsearch container status
docker ps | grep elasticsearch

# View Elasticsearch logs
docker logs elasticsearch --tail 100 -f

# Check cluster health
curl -u elastic:password "http://localhost:9200/_cluster/health?pretty"

# List all indices
curl -u elastic:password "http://localhost:9200/_cat/indices?v&s=store.size:desc"

# Check node stats
curl -u elastic:password "http://localhost:9200/_nodes/stats?pretty"

# View pending tasks
curl -u elastic:password "http://localhost:9200/_cluster/pending_tasks?pretty"

# Check shard allocation
curl -u elastic:password "http://localhost:9200/_cat/shards?v"
```

### Performance Tuning

#### For Search-Heavy Workloads
```bash
# Increase query cache size
curl -X PUT -u elastic:password "http://localhost:9200/my-index/_settings" \
  -H "Content-Type: application/json" \
  -d '{
    "index.queries.cache.enabled": true,
    "index.requests.cache.enable": true
  }'
```

#### For Write-Heavy Workloads
```bash
# Adjust refresh interval
curl -X PUT -u elastic:password "http://localhost:9200/my-index/_settings" \
  -H "Content-Type: application/json" \
  -d '{"index.refresh_interval": "30s"}'
```

## Security Best Practices

1. **Change Default Passwords**: Always change from default credentials
2. **Use HTTPS**: Enable SSL/TLS in production
3. **Restrict Network Access**: Use firewall rules
4. **Enable Audit Logging**: Track security events
5. **Regular Backups**: Automate snapshot creation
6. **Role-Based Access**: Create users with minimal required permissions
7. **Monitor Access Logs**: Review unauthorized access attempts

## Resources

- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Kibana Documentation](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Elasticsearch API Reference](https://www.elastic.co/guide/en/elasticsearch/reference/current/rest-apis.html)
- [Query DSL](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html)
