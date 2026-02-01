#!/bin/bash
set -e

echo "=== K3s Kubernetes with Portainer Installation Script ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${GREEN}Loading configuration from .env${NC}"
    export $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | xargs)
else
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please create .env from .env.example"
    exit 1
fi

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Installing kubectl${NC}"
if command -v kubectl &> /dev/null; then
    echo "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    echo -e "${GREEN}kubectl installed successfully${NC}"
fi

echo -e "${YELLOW}Step 2: Installing K3s${NC}"
if command -v k3s &> /dev/null; then
    echo "K3s already installed: $(k3s --version | head -n1)"
else
    INSTALL_K3S_VERSION="${K3S_VERSION}"
    if [ "$K3S_DISABLE_TRAEFIK" = "true" ]; then
        curl -sfL https://get.k3s.io | sh -s - --disable traefik
    else
        curl -sfL https://get.k3s.io | sh -
    fi
    echo -e "${GREEN}K3s installed successfully${NC}"
fi

echo -e "${YELLOW}Step 3: Waiting for K3s to be ready${NC}"
sleep 10
until kubectl get nodes 2>/dev/null | grep -q "Ready"; do
    echo "Waiting for K3s..."
    sleep 5
done
echo -e "${GREEN}K3s is ready${NC}"

echo -e "${YELLOW}Step 4: Setting up kubeconfig for non-root user${NC}"
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
    mkdir -p "$USER_HOME/.kube"
    cp /etc/rancher/k3s/k3s.yaml "$USER_HOME/.kube/config"
    chown -R $SUDO_USER:$SUDO_USER "$USER_HOME/.kube"
    chmod 600 "$USER_HOME/.kube/config"
    echo -e "${GREEN}Kubeconfig copied to $USER_HOME/.kube/config${NC}"
fi

echo -e "${YELLOW}Step 5: Creating Portainer Agent namespace${NC}"
kubectl create namespace ${PORTAINER_AGENT_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

echo -e "${YELLOW}Step 6: Deploying Portainer Agent${NC}"

# Create Portainer Agent deployment
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: portainer-sa-clusteradmin
  namespace: ${PORTAINER_AGENT_NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: portainer-crb-clusteradmin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: portainer-sa-clusteradmin
  namespace: ${PORTAINER_AGENT_NAMESPACE}
---
apiVersion: v1
kind: Service
metadata:
  name: portainer-agent
  namespace: ${PORTAINER_AGENT_NAMESPACE}
spec:
  type: NodePort
  selector:
    app: portainer-agent
  ports:
    - name: http
      protocol: TCP
      port: 9001
      targetPort: 9001
      nodePort: 30091
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: portainer-agent
  namespace: ${PORTAINER_AGENT_NAMESPACE}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: portainer-agent
  template:
    metadata:
      labels:
        app: portainer-agent
    spec:
      serviceAccountName: portainer-sa-clusteradmin
      containers:
      - name: portainer-agent
        image: portainer/agent:latest
        ports:
        - containerPort: 9001
          protocol: TCP
        env:
        - name: LOG_LEVEL
          value: INFO
        - name: AGENT_CLUSTER_ADDR
          value: portainer-agent
        volumeMounts:
        - name: docker-socket
          mountPath: /var/run/docker.sock
          readOnly: true
      volumes:
      - name: docker-socket
        hostPath:
          path: /var/run/docker.sock
          type: Socket
EOF

echo -e "${YELLOW}Step 6: Waiting for Portainer Agent to be ready${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/portainer-agent -n ${PORTAINER_AGENT_NAMESPACE}

# Get node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}K3s with Portainer Agent installed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Cluster Information:"
echo "  - K3s Version: $(k3s --version | head -n1)"
echo "  - Node IP: $NODE_IP"
echo "  - Portainer Agent: http://$NODE_IP:30091"
echo ""
echo "Portainer Agent Access:"
echo "  - Agent Endpoint: $NODE_IP:30091"
echo ""
echo "Next Steps:"
echo "1. Login to your Portainer instance: ${PORTAINER_URL}"
echo "2. Go to Environments → Add Environment"
echo "3. Select 'Agent' as environment type"
echo "4. Enter Environment details:"
echo "   - Name: K3s Cluster"
echo "   - Environment URL: $NODE_IP:30091"
echo "5. Click 'Connect'"
echo ""
echo "Kubectl commands (run as $SUDO_USER):"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
