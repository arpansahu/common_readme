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
