# K3s Kubernetes with Portainer Agent

Lightweight Kubernetes cluster using K3s with Portainer Agent for centralized management through your existing Portainer instance.

## Prerequisites

- Ubuntu Server 22.04+
- At least 1 CPU core and 512MB RAM (2GB recommended)
- Existing Portainer instance (https://portainer.arpansahu.space)
- Root or sudo access

## Quick Start

```bash
# 1. Copy files to server
scp -r kubernetes_k3s/ user@server:"AWS Deployment/"

# 2. SSH to server
ssh user@server
cd "AWS Deployment/kubernetes_k3s"

# 3. Create .env from example
cp .env.example .env
nano .env  # Edit if needed

# 4. Install K3s
chmod +x install.sh
sudo ./install.sh

# 5. Deploy Portainer Agent
export KUBECONFIG=/home/$USER/.kube/config
kubectl apply -n portainer -f https://downloads.portainer.io/ce2-19/portainer-agent-k8s-nodeport.yaml

# 6. Get agent port
kubectl get svc -n portainer portainer-agent

# 7. Connect to Portainer
# Login to: https://portainer.arpansahu.space
# Go to: Environments → Add Environment → Agent
# Enter: <server-ip>:<nodeport>
```

## Configuration

`.env.example`:
```bash
K3S_VERSION=stable
K3S_CLUSTER_NAME=arpansahu-k3s
PORTAINER_AGENT_NAMESPACE=portainer
PORTAINER_AGENT_PORT=9001
PORTAINER_URL=https://portainer.arpansahu.space
K3S_DATA_DIR=/var/lib/rancher/k3s
K3S_DISABLE_TRAEFIK=true
```

## Installation Details

### kubectl Installation

The `install.sh` script first installs kubectl if not already present:
- Downloads latest stable kubectl binary
- Installs to `/usr/local/bin/kubectl`
- Skips if kubectl already exists

### K3s Installation

The `install.sh` script:
1. Installs K3s (lightweight Kubernetes)
2. Waits for cluster to be ready
3. Sets up kubeconfig for non-root user (`~/.kube/config`)
4. Creates portainer namespace

### Portainer Agent Deployment

Deploy the agent manually after K3s installation:

```bash
# Set kubeconfig
export KUBECONFIG=/home/$USER/.kube/config

# Deploy agent
kubectl apply -n portainer -f https://downloads.portainer.io/ce2-19/portainer-agent-k8s-nodeport.yaml

# Verify deployment
kubectl get pods -n portainer
kubectl get svc -n portainer
```

## Connecting to Portainer

### Get Connection Details

```bash
# Get server IP
hostname -I | awk '{print $1}'

# Get NodePort
kubectl get svc -n portainer portainer-agent -o jsonpath='{.spec.ports[0].nodePort}'

# Example endpoint: 192.168.1.200:30778
```

### Add Environment in Portainer

1. Login: https://portainer.arpansahu.space
2. **Environments** → **Add environment**
3. Select **Agent**
4. **Environment details:**
   - Name: `K3s Cluster`
   - Environment URL: `192.168.1.200:30778` (use your IP and port)
5. Click **Connect**

### Verify Connection

```bash
# Check agent status
kubectl get pods -n portainer

# View agent logs
kubectl logs -n portainer -l app=portainer-agent

# Test connectivity
curl http://localhost:<nodeport>
```

## Managing Applications

### Via Portainer UI

1. Select K3s environment in Portainer
2. **Applications** → **Add application**
3. Configure deployment settings
4. Click **Deploy**

### Via kubectl

```bash
# Create deployment
kubectl create deployment nginx --image=nginx:alpine

# Expose as service
kubectl expose deployment nginx --port=80 --type=NodePort

# Check resources
kubectl get all
kubectl get pods
kubectl get services

# Get service URL
kubectl get svc nginx -o jsonpath='{.spec.ports[0].nodePort}'
# Access: http://<server-ip>:<nodeport>
```

### Via YAML Manifests

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  type: NodePort
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

Apply:
```bash
kubectl apply -f deployment.yaml
```

## kubectl Commands

### Basic Operations

```bash
# Cluster information
kubectl cluster-info
kubectl get nodes

# View resources
kubectl get all -A
kubectl get pods -A
kubectl get services -A
kubectl get namespaces

# Describe resources
kubectl describe pod <pod-name>
kubectl describe svc <service-name>

# Logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # Follow logs
kubectl logs <pod-name> --previous  # Previous container logs

# Execute commands
kubectl exec -it <pod-name> -- /bin/sh
kubectl exec <pod-name> -- ls /app

# Port forwarding
kubectl port-forward pod/<pod-name> 8080:80
kubectl port-forward svc/<service-name> 8080:80
```

### Deployment Management

```bash
# Scale deployment
kubectl scale deployment <name> --replicas=3

# Update image
kubectl set image deployment/<name> container-name=new-image:tag

# Restart deployment
kubectl rollout restart deployment/<name>

# Rollout history
kubectl rollout history deployment/<name>

# Rollback
kubectl rollout undo deployment/<name>

# Delete resources
kubectl delete deployment <name>
kubectl delete service <name>
kubectl delete -f deployment.yaml
```

### Namespace Management

```bash
# List namespaces
kubectl get namespaces

# Create namespace
kubectl create namespace my-namespace

# Switch context to namespace
kubectl config set-context --current --namespace=my-namespace

# Delete namespace
kubectl delete namespace my-namespace
```

## Backup and Restore

### Backup Script

```bash
#!/bin/bash
# backup-k3s.sh

BACKUP_DIR="/backup/k3s/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup K3s data directory
sudo tar czf "$BACKUP_DIR/k3s-data.tar.gz" /var/lib/rancher/k3s

# Backup all Kubernetes resources
kubectl get all -A -o yaml > "$BACKUP_DIR/all-resources.yaml"

# Backup persistent volumes
kubectl get pv,pvc -A -o yaml > "$BACKUP_DIR/volumes.yaml"

# Backup namespaces and configs
kubectl get namespaces -o yaml > "$BACKUP_DIR/namespaces.yaml"
kubectl get configmaps -A -o yaml > "$BACKUP_DIR/configmaps.yaml"
kubectl get secrets -A -o yaml > "$BACKUP_DIR/secrets.yaml"

echo "Backup completed: $BACKUP_DIR"
```

### Restore Script

```bash
#!/bin/bash
# restore-k3s.sh

BACKUP_DIR="/backup/k3s/20260201_100000"

# Stop K3s
sudo systemctl stop k3s

# Restore K3s data
sudo tar xzf "$BACKUP_DIR/k3s-data.tar.gz" -C /

# Start K3s
sudo systemctl start k3s
sleep 30

# Wait for cluster to be ready
until kubectl get nodes | grep -q "Ready"; do
    echo "Waiting for cluster..."
    sleep 5
done

# Restore resources
kubectl apply -f "$BACKUP_DIR/all-resources.yaml"

echo "Restore completed"
```

## Troubleshooting

### K3s Issues

```bash
# Check K3s status
sudo systemctl status k3s

# View K3s logs
sudo journalctl -u k3s -n 100 --no-pager
sudo journalctl -u k3s -f  # Follow logs

# Restart K3s
sudo systemctl restart k3s

# Check K3s version
k3s --version

# Check ports
sudo netstat -tlnp | grep -E '6443|10250'
```

### Portainer Agent Issues

```bash
# Check agent pod status
kubectl get pods -n portainer

# View agent logs
kubectl logs -n portainer -l app=portainer-agent
kubectl logs -n portainer -l app=portainer-agent -f  # Follow

# Check agent service
kubectl get svc -n portainer

# Describe agent pod
kubectl describe pod -n portainer -l app=portainer-agent

# Test agent port
kubectl get svc -n portainer portainer-agent -o jsonpath='{.spec.ports[0].nodePort}'
curl http://localhost:<nodeport>

# Restart agent
kubectl rollout restart deployment -n portainer portainer-agent
```

### Pod Issues

```bash
# Check pod status
kubectl get pods -n <namespace>

# Describe pod (shows events)
kubectl describe pod <pod-name> -n <namespace>

# View pod logs
kubectl logs <pod-name> -n <namespace>

# Check events
kubectl get events -A --sort-by='.lastTimestamp'

# Check node resources
kubectl top nodes
kubectl describe nodes
```

### Network Issues

```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check network pods
kubectl get pods -n kube-system

# Restart CoreDNS
kubectl rollout restart deployment -n kube-system coredns
```

### Storage Issues

```bash
# Check persistent volumes
kubectl get pv
kubectl get pvc -A

# Describe PVC
kubectl describe pvc <pvc-name> -n <namespace>

# Check disk space
df -h
du -sh /var/lib/rancher/k3s/*
```

### Connection Issues from Portainer

```bash
# From Portainer server, test connection
telnet <k3s-server-ip> <nodeport>
curl http://<k3s-server-ip>:<nodeport>

# Check firewall
sudo ufw status
sudo ufw allow <nodeport>/tcp

# Check if agent is listening
sudo netstat -tlnp | grep <nodeport>
```

### Performance Issues

```bash
# Check resource usage
kubectl top nodes
kubectl top pods -A

# Check system resources
free -h
df -h
vmstat 5

# Check K3s resource limits
sudo cat /etc/systemd/system/k3s.service
```

### Uninstall K3s

```bash
# Complete uninstall
sudo /usr/local/bin/k3s-uninstall.sh

# Verify removal
which k3s
which kubectl
ls /var/lib/rancher/k3s
```

## Security Best Practices

1. **Kubeconfig Permissions**: Ensure `~/.kube/config` has proper permissions (600)
2. **RBAC**: Use role-based access control for users and services
3. **Network Policies**: Implement network policies for pod communication
4. **Secrets Management**: Use Kubernetes secrets for sensitive data
5. **Regular Updates**: Keep K3s and container images updated
6. **Resource Limits**: Set CPU/memory limits on pods
7. **Security Context**: Define security contexts for pods

## Resources

- [K3s Official Documentation](https://docs.k3s.io/)
- [Portainer Agent Documentation](https://docs.portainer.io/admin/environments/add/kubernetes/agent)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## Support

For issues:
1. Check [Troubleshooting](#troubleshooting) section
2. View K3s logs: `sudo journalctl -u k3s -f`
3. View agent logs: `kubectl logs -n portainer -l app=portainer-agent`
4. [K3s GitHub Issues](https://github.com/k3s-io/k3s/issues)
5. [Portainer Community Forums](https://www.portainer.io/community)

---

## SSL Certificates for Kubernetes

### Overview

For Kubernetes deployments requiring SSL certificates (Java apps like Kafka, Ingress with TLS), certificates from nginx can be converted to Kubernetes secrets and Java keystores.

### Architecture

```
nginx SSL Certificates (/etc/nginx/ssl/arpansahu.space/)
    ↓
Java Keystore Generation
    ├─→ Kubernetes Secrets (for K3s pods)
    └─→ MinIO Storage (for Django projects)
```

### Automated SSL Certificate Management

Two scripts for different purposes:

#### 1️⃣ K3s SSL Keystore Renewal

[`1_renew_k3s_ssl_keystores.sh`](./1_renew_k3s_ssl_keystores.sh) - Updates Kubernetes cluster certificates

**Purpose:** Renew SSL certificates for K3s cluster (Ingress, Kafka pods, etc.)

**What it does:**
1. ✅ Generates Java keystores from nginx certificates
2. ✅ Creates/updates Kubernetes TLS secret (`arpansahu-tls`)
3. ✅ Creates/updates Kubernetes keystore secret (`kafka-ssl-keystore`)
4. ✅ Stores keystores in `/var/lib/rancher/k3s/ssl/keystores/`

**Run after nginx certificate renewal:**
```bash
cd "AWS Deployment/kubernetes_k3s"
chmod +x 1_renew_k3s_ssl_keystores.sh
./1_renew_k3s_ssl_keystores.sh
```

#### 2️⃣ Upload Keystores to MinIO

[`2_upload_keystores_to_minio.sh`](./2_upload_keystores_to_minio.sh) - Uploads certificates to MinIO for Django projects

**Purpose:** Make SSL certificates securely available for Django projects to dynamically fetch and cache

**What it does:**
1. ✅ Uploads `fullchain.pem` to MinIO (private path)
2. ✅ Uploads `kafka.keystore.jks` to MinIO (private path)
3. ✅ Uploads `kafka.truststore.jks` to MinIO (private path)
4. ✅ Requires authentication to access (secure storage)

**Prerequisites:**
- MinIO client (`mc`) installed
- MinIO alias configured: `mc alias set minio https://minioapi.arpansahu.space ACCESS_KEY SECRET_KEY`
- K3s keystores generated (run script #1 first)

**Run after keystore generation:**
```bash
cd "AWS Deployment/kubernetes_k3s"
chmod +x 2_upload_keystores_to_minio.sh
./2_upload_keystores_to_minio.sh
```

**Files uploaded to:**
- `s3://arpansahu-one-bucket/keystores/private/kafka/fullchain.pem`
- `s3://arpansahu-one-bucket/keystores/private/kafka/kafka.keystore.jks`
- `s3://arpansahu-one-bucket/keystores/private/kafka/kafka.truststore.jks`

**Django integration:**
```python
# common_utils/kafka_ssl.py
import boto3
from functools import lru_cache
from django.conf import settings

@lru_cache(maxsize=1)
def get_kafka_ssl_cert():
    """Fetch latest SSL certificate from MinIO (authenticated)"""
    s3 = boto3.client('s3',
        endpoint_url='https://minioapi.arpansahu.space',
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY
    )
    obj = s3.get_object(
        Bucket='arpansahu-one-bucket',
        Key='keystores/private/kafka/fullchain.pem'
    )
    return obj['Body'].read().decode()

# Usage in Kafka connection
ssl_context = ssl.create_default_context()
ssl_context.load_verify_locations(cadata=get_kafka_ssl_cert())
```

#### Complete Automation

Add both scripts to `~/deploy_certs.sh` for automatic execution after certificate renewal:

```bash
# At end of ~/deploy_certs.sh
if command -v kubectl &> /dev/null; then
    echo "Updating K3s SSL certificates..."
    cd "$HOME/AWS Deployment/kubernetes_k3s"
    
    # Renew K3s keystores
    ./1_renew_k3s_ssl_keystores.sh
    
    # Upload to MinIO for Django projects
    ./2_upload_keystores_to_minio.sh
    
    echo "✅ K3s and MinIO certificates updated"
fi
```

### Manual Certificate Deployment

#### 1. Create TLS Secret

```bash
# Create TLS secret for Ingress
sudo kubectl create secret tls arpansahu-tls \
  --cert=/etc/nginx/ssl/arpansahu.space/fullchain.pem \
  --key=/etc/nginx/ssl/arpansahu.space/privkey.pem \
  --dry-run=client -o yaml | sudo kubectl apply -f -
```

#### 2. Generate Java Keystores (for Kafka/Java apps)

```bash
# Set passwords (use strong passwords)
KEYSTORE_PASS="your-secure-password"
TRUSTSTORE_PASS="your-secure-password"
KEY_PASS="your-secure-password"

# Create SSL directory
sudo mkdir -p /var/lib/rancher/k3s/ssl/keystores
cd /var/lib/rancher/k3s/ssl/keystores

# Convert PEM to PKCS12
sudo openssl pkcs12 -export \
  -in /etc/nginx/ssl/arpansahu.space/fullchain.pem \
  -inkey /etc/nginx/ssl/arpansahu.space/privkey.pem \
  -out kafka.p12 \
  -name kafka \
  -passout pass:$KEYSTORE_PASS

# Create keystore
sudo keytool -importkeystore -noprompt \
  -deststorepass $KEYSTORE_PASS \
  -destkeypass $KEY_PASS \
  -destkeystore kafka.keystore.jks \
  -srckeystore kafka.p12 \
  -srcstoretype PKCS12 \
  -srcstorepass $KEYSTORE_PASS \
  -alias kafka

# Create truststore
sudo rm -f kafka.truststore.jks
sudo keytool -keystore kafka.truststore.jks \
  -alias CARoot \
  -import \
  -file /etc/nginx/ssl/arpansahu.space/fullchain.pem \
  -storepass $TRUSTSTORE_PASS \
  -noprompt

# Set permissions
sudo chmod 644 *.jks
```

#### 3. Create Keystore Secret

```bash
sudo kubectl create secret generic kafka-ssl-keystore \
  --from-file=kafka.keystore.jks=/var/lib/rancher/k3s/ssl/keystores/kafka.keystore.jks \
  --from-file=kafka.truststore.jks=/var/lib/rancher/k3s/ssl/keystores/kafka.truststore.jks \
  --from-literal=keystore-password=$KEYSTORE_PASS \
  --from-literal=truststore-password=$TRUSTSTORE_PASS \
  --from-literal=key-password=$KEY_PASS \
  --dry-run=client -o yaml | sudo kubectl apply -f -
```

### Using Certificates in Deployments

#### Kafka Deployment Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kafka
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
      - name: kafka
        image: confluentinc/cp-kafka:7.8.0
        env:
        - name: KAFKA_SSL_KEYSTORE_LOCATION
          value: /etc/kafka/secrets/kafka.keystore.jks
        - name: KAFKA_SSL_KEYSTORE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: kafka-ssl-keystore
              key: keystore-password
        - name: KAFKA_SSL_KEY_PASSWORD
          valueFrom:
            secretKeyRef:
              name: kafka-ssl-keystore
              key: key-password
        - name: KAFKA_SSL_TRUSTSTORE_LOCATION
          value: /etc/kafka/secrets/kafka.truststore.jks
        - name: KAFKA_SSL_TRUSTSTORE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: kafka-ssl-keystore
              key: truststore-password
        volumeMounts:
        - name: kafka-ssl
          mountPath: /etc/kafka/secrets
          readOnly: true
      volumes:
      - name: kafka-ssl
        secret:
          secretName: kafka-ssl-keystore
```

#### Ingress with TLS Example

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: default
spec:
  tls:
  - hosts:
    - app.arpansahu.space
    secretName: arpansahu-tls
  rules:
  - host: app.arpansahu.space
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

### Jenkins Credential Upload

#### Via Jenkins UI

1. Navigate to: https://jenkins.arpansahu.space
2. **Manage Jenkins → Credentials → (global) → Add Credentials**
3. Configure:
   - **Kind:** Secret text
   - **ID:** `kafka-ssl-ca-cert`
   - **Secret:** Paste certificate content
   - **Description:** `Kafka SSL CA Certificate for Kubernetes`

**Get certificate:**
```bash
ssh server "cat /etc/nginx/ssl/arpansahu.space/fullchain.pem" | pbcopy
```

#### Using in Jenkinsfile

```groovy
pipeline {
    agent any
    
    stages {
        stage('Deploy to K8s') {
            steps {
                withCredentials([string(credentialsId: 'kafka-ssl-ca-cert', variable: 'KAFKA_CERT')]) {
                    sh '''
                        # Create secret in K8s
                        echo "$KAFKA_CERT" > kafka-cert.pem
                        
                        kubectl create secret generic kafka-ssl \
                            --from-file=ca-cert.pem=kafka-cert.pem \
                            --dry-run=client -o yaml | kubectl apply -f -
                        
                        rm kafka-cert.pem
                    '''
                }
            }
        }
    }
}
```

### Monitoring

#### Check Secrets

```bash
# List secrets
sudo kubectl get secrets

# Describe TLS secret
sudo kubectl describe secret arpansahu-tls

# Check keystore secret
sudo kubectl get secret kafka-ssl-keystore -o yaml

# Verify certificate expiry
sudo kubectl get secret arpansahu-tls -o jsonpath='{.data.tls\.crt}' | \
  base64 -d | openssl x509 -noout -dates
```

#### Verify Pods Using Secrets

```bash
# Check pod status
sudo kubectl get pods

# View pod logs
sudo kubectl logs deployment/kafka

# Exec into pod
sudo kubectl exec -it deployment/kafka -- ls /etc/kafka/secrets/
```

### Troubleshooting

**Secrets not updating:**
- K8s doesn't auto-restart pods when secrets update
- Force restart: `sudo kubectl rollout restart deployment/kafka`

**Permission errors:**
- Ensure keystores have correct permissions (644)
- Check pod security contexts

**Certificate mismatch:**
- Verify keystore was generated from correct PEM files
- Check keystore password matches secret

### Automation Integration

To integrate with certificate renewal automation:

1. Run SSL renewal setup (nginx):
```bash
cd "AWS Deployment/02-nginx"
./ssl-renewal-automation.sh
```

2. Add K3s keystore renewal to deploy script:
```bash
# Edit ~/deploy_certs.sh to include:
if command -v kubectl &> /dev/null; then
    echo "Updating K8s certificates..."
    cd "AWS Deployment/kubernetes_k3s"
    ./keystore-renewal-and-upload-to-jenkins.sh
fi
```

### Security Notes

1. **Secret Encryption:** Enable encryption at rest for K3s secrets
2. **RBAC:** Limit secret access to necessary service accounts
3. **Passwords:** Use strong keystore passwords
4. **Rotation:** Certificates auto-renew every 90 days
5. **Backups:** Include secrets in K3s backups

---
