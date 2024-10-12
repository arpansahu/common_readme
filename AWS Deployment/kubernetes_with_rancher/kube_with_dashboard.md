## Installing Kubernetes cluster and Setting A Dashboard

### Install Kubernetes CLI (kubectl)

1. Install kubectl:

    ```bash
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    ```

### Create a Rancher Cluster and Local Agent with Port Mappings in Docker 

1. 	Run Below Docker Command:

    ```bash
        docker run -d --restart=unless-stopped \
            -p 9380:80 -p 9343:443 \
            -v /etc/letsencrypt/live/arpansahu.me/fullchain.pem:/etc/rancher/ssl/cert.pem \
            -v /etc/letsencrypt/live/arpansahu.me/privkey.pem:/etc/rancher/ssl/key.pem \
            --privileged \
            --name rancher \
            rancher/rancher:latest \
            --no-cacerts
    ```

    Key points to note here: I already have lets encrypt generated certificates and they are automatically renewed too, so thats why,
    we are using this example from their official documentation

    This will deploy Rancher Dashboard with the specified ports 

2. Create User Password via UI:

    Go to public_ip:9343 or running in local use localhost/0.0.0.0:9343

    it will give u a command similar to the below command 

    ```bash
        docker logs container-id  2>&1 | grep "Bootstrap Password:"
    ```

    Run this command it will give you one time password
    copy it and fill it in ui and then you will get option to set the password and username is admin (default)

3. Copy Kube Config from the dashboard

    step 1: Click on home page 
    step 2: Click on local cluster
    step 3: beside the profile photo you can see a download or copy kube config button

4. Edit Kube Config in you terminal

    ```bash
        vi ~/.kube/config
    ```

    Paste the copied content which will look something like this:
    ```
        apiVersion: v1
        kind: Config
        clusters:
        - name: "local"
        cluster:
            server: "https://rancher.arpansahu.me/k8s/clusters/local"

        users:
        - name: "local"
        user:
            token: "kubeconfig-user-gf9xx76krz:68b7z8xf86zb6pvjjdbv9hhqtd29p72tr2kp8n65n6qp24fpf5ss8l"


        contexts:
        - name: "local"
        context:
            user: "local"
            cluster: "local"

        current-context: "local"
    ```

### Configure On-Premises Nginx as a Reverse Proxy

1. Edit Nginx Configuration

    ```bash
    sudo vi /etc/nginx/sites-available/services
    ```

    if /etc/nginx/sites-available/services does not exists

        1. Create a new configuration file: Create a new file in the Nginx configuration directory. The location of this directory varies depending on your  operating system and Nginx installation, but it’s usually found at /etc/nginx/sites-available/.

        ```bash
            touch /etc/nginx/sites-available/services
            vi /etc/nginx/sites-available/services
        ```


3. Add this server configuration

    ```bash
    # Map block to handle WebSocket upgrade
    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }

    server {
        listen         80;
        server_name    rancher.arpansahu.me;

        # Redirect all HTTP traffic to HTTPS
        if ($scheme = http) {
            return 301 https://$server_name$request_uri;
        }

        location / {
            proxy_pass https://0.0.0.0:9343;
            proxy_set_header        Host $host;
            proxy_set_header    X-Forwarded-Proto $scheme;

            # WebSocket support
            proxy_http_version      1.1;
            proxy_set_header        Upgrade $http_upgrade;
            proxy_set_header        Connection $connection_upgrade;
        }

        # Disable HTTP/2 by ensuring http2 is not included in the listen directive
        listen 443 ssl; # managed by Certbot
        ssl_certificate           /etc/letsencrypt/live/arpansahu.me/fullchain.pem; # managed by Certbot
        ssl_certificate_key       /etc/letsencrypt/live/arpansahu.me/privkey.pem;   # managed by Certbot
        include                   /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
        ssl_dhparam               /etc/letsencrypt/ssl-dhparams.pem;       # managed by Certbot
    }
    ```

    It is a key thing to note here since we are using External Nginx, it causes every request to upgrade to websocket when using 
    Rancher API through kubectl command so thats why we use below function 

    ```bash
        # Map block to handle WebSocket upgrade
        map $http_upgrade $connection_upgrade {
            default upgrade;
            ''      close;
        }
    ```

    Note: The purpose of this block is to prepare the Nginx configuration to handle WebSocket connections properly. When a client tries to initiate a WebSocket connection, it sends an Upgrade header. This block checks for that header and sets the $connection_upgrade variable to either upgrade (if a WebSocket upgrade is requested) or close (if it isn't).

4. Test the Nginx Configuration

    ```bas
    sudo nginx -t
    ```

5. Reload Nginx to apply the new configuration

    ```bash
    sudo systemctl reload nginx
    ```

### Accessing 

Access the Dashboard

https://rancher.arpansahu.me

you will be required to fill token for login

Access the cluster via Cli using kubectl

```bash
    kubectl get nodes
```

Note: 