# Django Integration with K3s SSL Certificates

This guide shows how Django projects deployed in Kubernetes can fetch SSL certificates from MinIO for secure Kafka connections.

## Overview

SSL certificates and keystores are automatically uploaded to MinIO after renewal and can be fetched by Django applications using authenticated S3 access.

**MinIO Storage Path:**
```
s3://arpansahu-one-bucket/
└── keystores/
    └── private/
        └── kafka/
            ├── fullchain.pem          (SSL certificate)
            ├── kafka.keystore.jks     (Java keystore)
            └── kafka.truststore.jks   (Java truststore)
```

**Access:** Private (requires authentication)

---

## Django Configuration

### 1. Environment Variables

Add these to your `.env` file:

```bash
# MinIO Configuration
AWS_S3_ENDPOINT_URL="https://minioapi.arpansahu.space"
AWS_ACCESS_KEY_ID="arpansahu"
AWS_SECRET_ACCESS_KEY="Gandu302@minio"
AWS_STORAGE_BUCKET_NAME="arpansahu-one-bucket"
AWS_S3_VERIFY=True
AWS_S3_ADDRESSING_STYLE="path"
AWS_S3_SIGNATURE_VERSION="s3v4"

# Kafka SSL Paths in MinIO
KAFKA_SSL_CERT_PATH="keystores/private/kafka/fullchain.pem"
KAFKA_SSL_KEYSTORE_PATH="keystores/private/kafka/kafka.keystore.jks"
KAFKA_SSL_TRUSTSTORE_PATH="keystores/private/kafka/kafka.truststore.jks"
```

### 2. Django Settings

Add to `settings.py`:

```python
# MinIO Configuration (for SSL certificates)
AWS_S3_ENDPOINT_URL = env('AWS_S3_ENDPOINT_URL')
AWS_ACCESS_KEY_ID = env('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = env('AWS_SECRET_ACCESS_KEY')
AWS_STORAGE_BUCKET_NAME = env('AWS_STORAGE_BUCKET_NAME')
AWS_S3_VERIFY = env.bool('AWS_S3_VERIFY', True)
AWS_S3_ADDRESSING_STYLE = env('AWS_S3_ADDRESSING_STYLE', 'path')
AWS_S3_SIGNATURE_VERSION = env('AWS_S3_SIGNATURE_VERSION', 's3v4')

# Kafka SSL Paths
KAFKA_SSL_CERT_PATH = env('KAFKA_SSL_CERT_PATH')
KAFKA_SSL_KEYSTORE_PATH = env('KAFKA_SSL_KEYSTORE_PATH')
KAFKA_SSL_TRUSTSTORE_PATH = env('KAFKA_SSL_TRUSTSTORE_PATH')
```

---

## Utility Functions

### Create `common_utils/kafka_ssl.py`

```python
"""
Utility functions to fetch Kafka SSL certificates from MinIO
"""
import boto3
import ssl
import tempfile
from functools import lru_cache
from pathlib import Path
from django.conf import settings


def _get_s3_client():
    """Create authenticated S3 client for MinIO"""
    return boto3.client(
        's3',
        endpoint_url=settings.AWS_S3_ENDPOINT_URL,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
        verify=settings.AWS_S3_VERIFY,
        config=boto3.session.Config(
            signature_version=settings.AWS_S3_SIGNATURE_VERSION,
            s3={'addressing_style': settings.AWS_S3_ADDRESSING_STYLE}
        )
    )


@lru_cache(maxsize=1)
def get_kafka_ssl_cert():
    """
    Fetch SSL certificate from MinIO
    
    Returns:
        str: Certificate content (PEM format)
    """
    s3 = _get_s3_client()
    
    response = s3.get_object(
        Bucket=settings.AWS_STORAGE_BUCKET_NAME,
        Key=settings.KAFKA_SSL_CERT_PATH
    )
    
    return response['Body'].read().decode('utf-8')


@lru_cache(maxsize=1)
def get_kafka_ssl_context():
    """
    Create SSL context with certificate from MinIO
    
    Returns:
        ssl.SSLContext: Configured SSL context for Kafka
    """
    cert_content = get_kafka_ssl_cert()
    
    # Create SSL context
    ssl_context = ssl.create_default_context()
    
    # Load certificate from memory
    ssl_context.load_verify_locations(cadata=cert_content)
    
    return ssl_context


def download_kafka_keystore(output_path: Path = None):
    """
    Download Java keystore from MinIO to local file
    
    Args:
        output_path: Local path to save keystore (default: /tmp/kafka.keystore.jks)
    
    Returns:
        Path: Path to downloaded keystore file
    """
    if output_path is None:
        output_path = Path(tempfile.gettempdir()) / "kafka.keystore.jks"
    
    s3 = _get_s3_client()
    
    s3.download_file(
        Bucket=settings.AWS_STORAGE_BUCKET_NAME,
        Key=settings.KAFKA_SSL_KEYSTORE_PATH,
        Filename=str(output_path)
    )
    
    return output_path


def download_kafka_truststore(output_path: Path = None):
    """
    Download Java truststore from MinIO to local file
    
    Args:
        output_path: Local path to save truststore (default: /tmp/kafka.truststore.jks)
    
    Returns:
        Path: Path to downloaded truststore file
    """
    if output_path is None:
        output_path = Path(tempfile.gettempdir()) / "kafka.truststore.jks"
    
    s3 = _get_s3_client()
    
    s3.download_file(
        Bucket=settings.AWS_STORAGE_BUCKET_NAME,
        Key=settings.KAFKA_SSL_TRUSTSTORE_PATH,
        Filename=str(output_path)
    )
    
    return output_path
```

---

## Usage Examples

### Python Kafka Client (kafka-python)

```python
from kafka import KafkaProducer, KafkaConsumer
from common_utils.kafka_ssl import get_kafka_ssl_context

# Get SSL context from MinIO
ssl_context = get_kafka_ssl_context()

# Producer with SSL
producer = KafkaProducer(
    bootstrap_servers=['kafka-server.arpansahu.space:9092'],
    security_protocol='SASL_SSL',
    sasl_mechanism='PLAIN',
    sasl_plain_username='admin',
    sasl_plain_password='Gandu302@kafka',
    ssl_context=ssl_context,
)

# Consumer with SSL
consumer = KafkaConsumer(
    'my-topic',
    bootstrap_servers=['kafka-server.arpansahu.space:9092'],
    security_protocol='SASL_SSL',
    sasl_mechanism='PLAIN',
    sasl_plain_username='admin',
    sasl_plain_password='Gandu302@kafka',
    ssl_context=ssl_context,
    auto_offset_reset='earliest',
    enable_auto_commit=True,
    group_id='my-consumer-group',
)
```

### Confluent Kafka (confluent-kafka-python)

```python
from confluent_kafka import Producer, Consumer
from common_utils.kafka_ssl import download_kafka_truststore
from pathlib import Path

# Download truststore to temp location
truststore_path = download_kafka_truststore()

# Producer configuration
producer_config = {
    'bootstrap.servers': 'kafka-server.arpansahu.space:9092',
    'security.protocol': 'SASL_SSL',
    'sasl.mechanism': 'PLAIN',
    'sasl.username': 'admin',
    'sasl.password': 'Gandu302@kafka',
    'ssl.ca.location': str(truststore_path),
}

producer = Producer(producer_config)

# Consumer configuration
consumer_config = {
    'bootstrap.servers': 'kafka-server.arpansahu.space:9092',
    'security.protocol': 'SASL_SSL',
    'sasl.mechanism': 'PLAIN',
    'sasl.username': 'admin',
    'sasl.password': 'Gandu302@kafka',
    'ssl.ca.location': str(truststore_path),
    'group.id': 'my-consumer-group',
    'auto.offset.reset': 'earliest',
}

consumer = Consumer(consumer_config)
```

### Django Channels with Kafka

```python
# consumers.py
from channels.generic.websocket import AsyncWebsocketConsumer
from common_utils.kafka_ssl import get_kafka_ssl_context
import asyncio
from kafka import KafkaConsumer
import json

class KafkaWebSocketConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        await self.accept()
        
        # Start Kafka consumer in background
        self.kafka_task = asyncio.create_task(self.consume_kafka())
    
    async def disconnect(self, close_code):
        if hasattr(self, 'kafka_task'):
            self.kafka_task.cancel()
    
    async def consume_kafka(self):
        """Consume messages from Kafka and send to WebSocket"""
        ssl_context = get_kafka_ssl_context()
        
        consumer = KafkaConsumer(
            'notifications',
            bootstrap_servers=['kafka-server.arpansahu.space:9092'],
            security_protocol='SASL_SSL',
            sasl_mechanism='PLAIN',
            sasl_plain_username='admin',
            sasl_plain_password='Gandu302@kafka',
            ssl_context=ssl_context,
            auto_offset_reset='latest',
            enable_auto_commit=True,
            group_id=f'websocket-{self.scope["user"].id}',
        )
        
        try:
            for message in consumer:
                await self.send(text_data=json.dumps({
                    'message': message.value.decode('utf-8'),
                    'timestamp': message.timestamp,
                }))
        except asyncio.CancelledError:
            consumer.close()
```

---

## Kubernetes Deployment

### ConfigMap for MinIO Credentials

```yaml
# k8s/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: django-starter-config
  namespace: default
data:
  AWS_S3_ENDPOINT_URL: "https://minioapi.arpansahu.space"
  AWS_STORAGE_BUCKET_NAME: "arpansahu-one-bucket"
  AWS_S3_VERIFY: "True"
  AWS_S3_ADDRESSING_STYLE: "path"
  AWS_S3_SIGNATURE_VERSION: "s3v4"
  KAFKA_SSL_CERT_PATH: "keystores/private/kafka/fullchain.pem"
  KAFKA_SSL_KEYSTORE_PATH: "keystores/private/kafka/kafka.keystore.jks"
  KAFKA_SSL_TRUSTSTORE_PATH: "keystores/private/kafka/kafka.truststore.jks"
```

### Secret for MinIO Access Keys

```yaml
# k8s/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: django-starter-minio-secret
  namespace: default
type: Opaque
stringData:
  AWS_ACCESS_KEY_ID: "arpansahu"
  AWS_SECRET_ACCESS_KEY: "Gandu302@minio"
```

### Deployment with SSL Integration

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: django-starter
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: django-starter
  template:
    metadata:
      labels:
        app: django-starter
    spec:
      containers:
      - name: django-starter
        image: harbor.arpansahu.space/arpansahu/django-starter:latest
        ports:
        - containerPort: 8000
        env:
        # MinIO Configuration from ConfigMap
        - name: AWS_S3_ENDPOINT_URL
          valueFrom:
            configMapKeyRef:
              name: django-starter-config
              key: AWS_S3_ENDPOINT_URL
        - name: AWS_STORAGE_BUCKET_NAME
          valueFrom:
            configMapKeyRef:
              name: django-starter-config
              key: AWS_STORAGE_BUCKET_NAME
        - name: KAFKA_SSL_CERT_PATH
          valueFrom:
            configMapKeyRef:
              name: django-starter-config
              key: KAFKA_SSL_CERT_PATH
        
        # MinIO Credentials from Secret
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: django-starter-minio-secret
              key: AWS_ACCESS_KEY_ID
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: django-starter-minio-secret
              key: AWS_SECRET_ACCESS_KEY
        
        # Other environment variables...
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

### Apply Kubernetes Manifests

```bash
# Create/update ConfigMap and Secret
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

# Deploy application
kubectl apply -f k8s/deployment.yaml

# Verify deployment
kubectl get pods -l app=django-starter
kubectl logs -l app=django-starter --tail=50
```

---

## Testing

### Test MinIO Access

```python
# Django shell
python manage.py shell

from common_utils.kafka_ssl import get_kafka_ssl_cert, get_kafka_ssl_context

# Test certificate fetch
cert = get_kafka_ssl_cert()
print(f"Certificate length: {len(cert)} bytes")
print(cert[:100])  # Print first 100 chars

# Test SSL context creation
ssl_context = get_kafka_ssl_context()
print(f"SSL Context: {ssl_context}")
```

### Test Kafka Connection

```python
from kafka import KafkaProducer
from common_utils.kafka_ssl import get_kafka_ssl_context

try:
    producer = KafkaProducer(
        bootstrap_servers=['kafka-server.arpansahu.space:9092'],
        security_protocol='SASL_SSL',
        sasl_mechanism='PLAIN',
        sasl_plain_username='admin',
        sasl_plain_password='Gandu302@kafka',
        ssl_context=get_kafka_ssl_context(),
    )
    print("✅ Kafka connection successful!")
except Exception as e:
    print(f"❌ Kafka connection failed: {e}")
```

---

## Troubleshooting

### Certificate Not Found

```python
# Check if certificate exists in MinIO
import boto3
from django.conf import settings

s3 = boto3.client('s3',
    endpoint_url=settings.AWS_S3_ENDPOINT_URL,
    aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
    aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY
)

# List files in keystore path
response = s3.list_objects_v2(
    Bucket=settings.AWS_STORAGE_BUCKET_NAME,
    Prefix='keystores/private/kafka/'
)

for obj in response.get('Contents', []):
    print(f"✅ Found: {obj['Key']} ({obj['Size']} bytes)")
```

### Access Denied (403)

- Verify AWS credentials are correct in `.env`
- Check MinIO user has read permissions on bucket
- Verify bucket policy doesn't block `keystores/private/*`

```bash
# Check bucket policy on server
ssh arpansahu@arpansahu.space 'mc anonymous get-json minio/arpansahu-one-bucket'
```

### SSL Certificate Expired

Certificates are auto-renewed. If expired:

```bash
# On server, regenerate and upload
cd ~/k3s_scripts
./1_renew_k3s_ssl_keystores.sh
./2_upload_keystores_to_minio.sh

# In Django, clear cache
from common_utils.kafka_ssl import get_kafka_ssl_cert
get_kafka_ssl_cert.cache_clear()
```

### Kafka Connection Failed

```bash
# Test Kafka connectivity from pod
kubectl exec -it <pod-name> -- bash
curl -v telnet://kafka-server.arpansahu.space:9092

# Check Kafka logs
ssh arpansahu@arpansahu.space
docker logs kafka-server
```

---

## Security Best Practices

1. **Never commit credentials** - Use environment variables or Kubernetes secrets
2. **Rotate credentials regularly** - Update MinIO access keys periodically
3. **Use least privilege** - MinIO user should only have read access to keystores
4. **Monitor access** - Check MinIO audit logs for unusual access patterns
5. **Cache certificates** - Use `@lru_cache` to minimize MinIO API calls
6. **Validate certificates** - Always set `AWS_S3_VERIFY=True` in production

---

## Automation

**SSL certificate renewal and distribution is fully automated.** See [SSL Automation Documentation](../ssl-automation/README.md) for complete details.

**What happens automatically:**
1. ✅ SSL certificates renewed by acme.sh (90-day cycle)
2. ✅ Kubernetes secrets updated (arpansahu-tls, kafka-ssl-keystore)
3. ✅ Keystores uploaded to MinIO (`keystores/private/kafka/`)
4. ✅ All services restarted with new certificates

Django apps will automatically fetch the latest certificates on next connection attempt (cache clears after app restart).

---

## Related Documentation

- [K3s SSL Management](./README.md#ssl-certificate-management)
- [MinIO Setup](../08-minio/README.md)
- [Kafka Configuration](../kafka/Kafka.md)
- [Django Storage Backends](/Users/arpansahu/projects/django_starter/django_starter/storage_backends.py)
