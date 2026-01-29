## Kubernetes with Portainer Setup

This guide explains how to set up Kubernetes (k3s) and integrate it with Portainer for easy management through a web UI. This is the actual, tested setup for single-node deployment with Nginx-managed HTTPS. After completing the Portainer setup from the main Portainer guide, follow these instructions to add Kubernetes support.

### Prerequisites

Before setting up Kubernetes with Portainer, ensure you have:

1. Ubuntu Server (20.04 / 22.04 recommended)
2. Portainer Server already installed and running
3. Portainer Agent configured for Docker
4. Minimum 2GB RAM (4GB recommended)
5. Root or sudo access
6. Nginx already configured with SSL certificates

### Installing k3s (Lightweight Kubernetes)

k3s is a lightweight Kubernetes distribution perfect for single-server deployments and edge computing.

Important: We install k3s WITHOUT Traefik (k3s default ingress controller) because we use Nginx for HTTPS termination.

1. Install k3s without Traefik

    ```bash
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -
    ```

    This command installs k3s with:
    - Kubernetes control plane
    - kubectl command-line tool
    - containerd container runtime
    - NO Traefik (we use Nginx instead)

    Why disable Traefik:
    - Nginx already handles HTTPS
    - Avoids port 80/443 conflicts
    - Simpler architecture
    - SSL certificates already in Nginx

2. Verify k3s Installation

    ```bash
    sudo systemctl status k3s
    ```

    Expected output: Active (running)

3. Check Kubernetes Nodes

    ```bash
    sudo kubectl get nodes
    ```

    Expected output:
    ```
    NAME     STATUS   ROLES                  AGE   VERSION
    server   Ready    control-plane,master   1m    v1.28.x
    ```

### Obtaining Kubeconfig

The kubeconfig file contains the credentials and configuration needed to connect your Kubernetes cluster to Portainer.

Note: k3s stores its configuration in `/etc/rancher/k3s/` directory. This is a k3s naming convention (k3s was developed by Rancher Labs), but we are NOT using Rancher software - only k3s + Portainer.

1. View kubeconfig content

    ```bash
    sudo cat /etc/rancher/k3s/k3s.yaml
    ```

    This file contains all the necessary information for Portainer to connect to your k3s cluster.

2. Copy kubeconfig to user directory (optional)

    ```bash
    mkdir -p ~/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown $(id -u):$(id -g) ~/.kube/config
    ```

3. Test kubectl access without sudo

    ```bash
    kubectl get nodes
    ```

### Adding Kubernetes Environment in Portainer

1. Access Portainer UI

    Go to: https://portainer.arpansahu.space

2. Navigate to Environments

    Portainer UI → Environments → Add Environment

3. Select Kubernetes

    Choose: Kubernetes

4. Choose Import Method

    Select: Import via kubeconfig

5. Paste Kubeconfig

    Copy the content from:

    ```bash
    sudo cat /etc/rancher/k3s/k3s.yaml
    ```

    Paste it into the Portainer kubeconfig field.

    Important: Make sure to copy the entire YAML content including:
    - apiVersion
    - clusters
    - contexts
    - users

6. Configure Environment

    - Name: `k3s-cluster` (or your preferred name)
    - Kubeconfig: (paste content from step 5)

7. Click Connect

    Portainer will auto-detect cluster resources including:
    - Namespaces
    - Deployments
    - Services
    - Pods
    - ConfigMaps
    - Secrets

### Verifying Kubernetes Integration

1. Check Portainer Environments

    Portainer UI → Environments

    You should see:
    - docker-prod-env (Docker)
    - k3s-cluster (Kubernetes)

2. Browse Kubernetes Resources

    Click on the Kubernetes environment to view:
    - Cluster details
    - Resource quotas
    - Namespaces
    - Workloads

3. Test kubectl Commands

    From terminal:

    ```bash
    kubectl get pods --all-namespaces
    kubectl get services --all-namespaces
    kubectl get deployments --all-namespaces
    ```

### Exposing Kubernetes Services via Nginx

Since we disabled Traefik and use Nginx for HTTPS, here's how to expose Kubernetes services:

1. Create Kubernetes Service with NodePort

    Example deployment and service (save as app.yaml):

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-app
      namespace: default
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
            image: nginx:latest
            ports:
            - containerPort: 80
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: my-app-service
      namespace: default
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
    kubectl apply -f app.yaml
    ```

2. Get NodePort

    ```bash
    kubectl get service my-app-service
    ```

    Note the NodePort (e.g., 30080)

3. Configure Nginx to Proxy to NodePort

    Edit Nginx configuration:

    ```bash
    sudo vi /etc/nginx/sites-available/services
    ```

    Add server block:

    ```nginx
    server {
        listen         80;
        server_name    app.arpansahu.space;
        
        # force https-redirects
        if ($scheme = http) {
            return 301 https://$server_name$request_uri;
        }

        location / {
            proxy_pass              http://127.0.0.1:30080;
            proxy_set_header        Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto $scheme;
        }

        listen 443 ssl;
        ssl_certificate /etc/letsencrypt/live/arpansahu.space/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/arpansahu.space/privkey.pem;
        include /etc/letsencrypt/options-ssl-nginx.conf;
        ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    }
    ```

4. Test and Reload Nginx

    ```bash
    sudo nginx -t
    sudo systemctl reload nginx
    ```

5. Access Application

    ```
    https://app.arpansahu.space
    ```

### Deploying Applications via Portainer

1. Navigate to Kubernetes Environment

    Portainer UI → Environments → k3s-cluster

2. Go to Applications

    Click: Applications

3. Add Application

    Click: Add application

4. Configure Deployment

    - Name: your-app-name
    - Image: your-docker-image
    - Port mapping: container-port
    - Replicas: number of pods

5. Create Service

    - Service type: NodePort
    - Port: container port
    - NodePort: specific port (30000-32767 range)

6. Deploy

    Click: Deploy the application

7. Configure Nginx (follow steps in previous section)

### Managing Kubernetes with kubectl

1. List all namespaces

    ```bash
    kubectl get namespaces
    ```

2. Create a new namespace

    ```bash
    kubectl create namespace my-app
    ```

3. List pods in a namespace

    ```bash
    kubectl get pods -n my-app
    ```

4. Describe a pod

    ```bash
    kubectl describe pod <pod-name> -n my-app
    ```

5. View pod logs

    ```bash
    kubectl logs <pod-name> -n my-app
    kubectl logs -f <pod-name> -n my-app  # Follow logs
    ```

6. Delete a pod

    ```bash
    kubectl delete pod <pod-name> -n my-app
    ```

7. Apply a YAML configuration

    ```bash
    kubectl apply -f deployment.yaml
    ```

8. Delete resources from YAML

    ```bash
    kubectl delete -f deployment.yaml
    ```

### Common Kubernetes Commands

1. Get cluster information

    ```bash
    kubectl cluster-info
    ```

2. Get all resources

    ```bash
    kubectl get all --all-namespaces
    ```

3. Get nodes with details

    ```bash
    kubectl get nodes -o wide
    ```

4. Get deployments

    ```bash
    kubectl get deployments --all-namespaces
    ```

5. Get services

    ```bash
    kubectl get services --all-namespaces
    ```

6. Get configmaps

    ```bash
    kubectl get configmaps --all-namespaces
    ```

7. Get secrets

    ```bash
    kubectl get secrets --all-namespaces
    ```

8. Scale a deployment

    ```bash
    kubectl scale deployment <deployment-name> --replicas=3 -n <namespace>
    ```

### Kubernetes Storage with k3s

k3s comes with local-path-provisioner by default for persistent volumes.

1. List storage classes

    ```bash
    kubectl get storageclass
    ```

    Expected output:
    ```
    NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE
    local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer
    ```

2. Create PersistentVolumeClaim

    Example YAML (save as pvc.yaml):

    ```yaml
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: my-pvc
      namespace: default
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
      storageClassName: local-path
    ```

    Apply:

    ```bash
    kubectl apply -f pvc.yaml
    ```

3. Verify PVC

    ```bash
    kubectl get pvc
    ```

    Expected output:
    ```
    NAME     STATUS   VOLUME                                     CAPACITY   ACCESS MODES
    my-pvc   Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   1Gi        RWO
    ```

### Debugging Common Issues

1. k3s Service Not Starting

    Cause: Port conflicts (especially if Traefik wasn't disabled) or insufficient resources

    Fix:

    ```bash
    sudo systemctl status k3s
    sudo journalctl -u k3s -f
    # Check for port 80/443 conflicts with Nginx
    sudo netstat -tulnp | grep -E ':(80|443|6443)'
    ```

2. Cannot Connect to Cluster

    Cause: Kubeconfig not properly configured

    Fix:

    ```bash
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    # Or copy to ~/.kube/config as shown earlier
    kubectl get nodes
    ```

3. Pods Stuck in Pending State

    Cause: Insufficient resources or storage issues

    Fix:

    ```bash
    kubectl describe pod <pod-name> -n <namespace>
    # Check Events section for errors
    kubectl get events --sort-by='.lastTimestamp' -n <namespace>
    ```

4. Portainer Cannot Connect to Kubernetes

    Cause: Incorrect kubeconfig or API server unreachable

    Fix:

    - Verify k3s is running: `sudo systemctl status k3s`
    - Check kubeconfig content is complete
    - Ensure server URL in kubeconfig is accessible
    - Try re-adding the environment in Portainer

5. Service Not Accessible via Nginx

    Cause: NodePort not configured or firewall blocking

    Fix:

    ```bash
    kubectl get service <service-name> -n <namespace>
    # Check NodePort value
    curl http://127.0.0.1:<nodeport>
    # Should return response from your app
    sudo nginx -t
    sudo systemctl reload nginx
    ```

6. Port 80/443 Already in Use

    Cause: Traefik was installed (forgot to disable it)

    Fix:

    ```bash
    # Uninstall k3s completely
    /usr/local/bin/k3s-uninstall.sh
    
    # Reinstall with Traefik disabled
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -
    ```

### Uninstalling k3s

If you need to completely remove k3s:

1. Run k3s uninstall script

    ```bash
    /usr/local/bin/k3s-uninstall.sh
    ```

2. Verify removal

    ```bash
    sudo systemctl status k3s
    # Should show: Unit k3s.service could not be found
    ```

3. Clean up remaining files (if needed)

    ```bash
    sudo rm -rf /etc/rancher
    sudo rm -rf /var/lib/rancher
    ```

### Security Best Practices

1. Use namespaces to isolate applications

    ```bash
    kubectl create namespace production
    kubectl create namespace development
    ```

2. Implement Resource Quotas

    ```bash
    kubectl create quota my-quota --hard=cpu=2,memory=2Gi,pods=10 -n my-namespace
    ```

3. Use RBAC (Role-Based Access Control)

    - Create service accounts for applications
    - Assign minimal required permissions
    - Avoid using default service account

4. Enable Pod Security Policies

    - Restrict privileged containers
    - Control volume types
    - Enforce security contexts

5. Regularly update k3s

    ```bash
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -
    ```

6. SSL/TLS Termination

    - Keep all SSL certificates in Nginx
    - Don't expose NodePorts directly to internet
    - Always proxy through Nginx for HTTPS

### Monitoring Kubernetes

1. Check cluster resource usage

    ```bash
    kubectl top nodes
    kubectl top pods --all-namespaces
    ```

    Note: Metrics server must be installed for these commands to work.

2. Install metrics server (if not present)

    ```bash
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    ```

3. Verify metrics server is running

    ```bash
    kubectl get deployment metrics-server -n kube-system
    ```

### Architecture Overview

This is the actual, production-tested architecture:

```
Internet (HTTPS)
   │
   └─ Nginx (Port 443)
        │ 
        │ [SSL Termination Here]
        │
        ├─ Portainer UI (Port 9998)
        │    └─ Manages Docker + Kubernetes
        │
        └─ Kubernetes Services (NodePorts 30000-32767)
             │
             └─ k3s Cluster (No Traefik)
                  ├─ Namespaces
                  ├─ Deployments
                  ├─ Services (NodePort)
                  ├─ Pods
                  └─ Persistent Volumes (local-path)
```

Key Points:
- Nginx owns all SSL/HTTPS
- k3s has NO Traefik (disabled at install)
- Services use NodePort type
- Nginx proxies to NodePorts
- Portainer connects via kubeconfig

### Final Verification Checklist

Run these commands to verify everything is working:

```bash
# Check k3s is running
sudo systemctl status k3s

# Check Traefik is NOT running (important)
kubectl get pods -n kube-system | grep traefik
# Should return: No resources found

# Check nodes
kubectl get nodes

# Check all pods
kubectl get pods --all-namespaces

# Check cluster info
kubectl cluster-info

# Check Nginx is running
sudo systemctl status nginx

# Check no port conflicts
sudo netstat -tulnp | grep -E ':(80|443)'
# Should only show nginx, not traefik
```

Then check in Portainer UI:
- Navigate to Environments
- Click on k3s-cluster
- Verify you can see all Kubernetes resources

### What This Setup Provides

After following this guide, you will have:

1. Lightweight Kubernetes cluster (k3s) running
2. NO Traefik (avoids port conflicts with Nginx)
3. Kubernetes integrated with Portainer via kubeconfig
4. Web UI management for Kubernetes resources
5. kubectl command-line access
6. Persistent storage support via local-path
7. Multi-environment management (Docker + Kubernetes)
8. Production-ready container orchestration
9. All HTTPS handled by Nginx (single point of SSL management)
10. Easy application deployment and scaling

### Why This Architecture Works

1. Nginx handles all HTTPS
   - Single SSL certificate management point
   - No Traefik certificate conflicts
   - Familiar Nginx configuration

2. k3s without Traefik
   - No port 80/443 conflicts
   - Simpler architecture
   - Less resource usage

3. NodePort Services
   - Direct access from Nginx
   - No ingress controller needed
   - Predictable port mapping

4. Portainer via kubeconfig
   - No additional agents needed
   - Clean integration
   - Full cluster visibility

### Example Kubernetes Resources

| Resource Type        | Command to View                              |
| -------------------- | -------------------------------------------- |
| Nodes                | kubectl get nodes                            |
| Namespaces           | kubectl get namespaces                       |
| Pods                 | kubectl get pods --all-namespaces            |
| Deployments          | kubectl get deployments --all-namespaces     |
| Services             | kubectl get services --all-namespaces        |
| ConfigMaps           | kubectl get configmaps --all-namespaces      |
| Secrets              | kubectl get secrets --all-namespaces         |
| Persistent Volumes   | kubectl get pv                               |
| Storage Classes      | kubectl get storageclass                     |

### Quick Reference: NodePort Range

Kubernetes NodePorts must be in range: **30000-32767**

When creating services:
- Use specific NodePort (e.g., 30080)
- Then configure Nginx to proxy to that port
- Keep a list of used NodePorts to avoid conflicts

For Portainer setup, see: [Portainer Installation Guide](../Portainer.md)
