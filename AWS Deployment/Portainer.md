## Portainer
   
Portainer is a web UI to manage your docker, and kubernetes. Portainer consists of two elements, the Portainer Server, and the Portainer Agent. Both elements run as lightweight Docker containers on a Docker engine.

### Installing Portainer

1. **Create a Docker Volume for Portainer Data (optional but recommended):**
   This step is optional but recommended as it allows you to persist Portainer's data across container restarts.

    ```bash
    docker volume create portainer_data
    ```

2. **Run Portainer Container:**
   Run the Portainer container using the following command. Replace `/var/run/docker.sock` with the path to your Docker socket if it's in a different location.

    ```bash
    docker run -d -p 0.0.0.0:9998:9000 -p 9444:8000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
    to use it in nginx server configuration
    ```

   This command pulls the Portainer Community Edition image from Docker Hub, creates a persistent volume for Portainer data, and starts the Portainer container. The `-p 9000:9000` option maps Portainer's web interface to port 9000 on your host.

3. **Access Portainer UI:**
   Open your web browser and go to `http://localhost:9000` (or replace `localhost` with your server's IP address if you are using a remote server). You will be prompted to set up an admin user and password.

4. **Connect Portainer to the Docker Daemon:**
   On the Portainer setup page, choose the "Docker" environment, and connect Portainer to the Docker daemon. You can usually use the default settings (`unix:///var/run/docker.sock` for the Docker API endpoint).

5. **Complete Setup:**
   Follow the on-screen instructions to complete the setup process. You may choose to deploy a local agent for better performance, but it's not required for basic functionality.

Once the setup is complete, you should have access to the Portainer dashboard, where you can manage and monitor your Docker containers, images, volumes, and networks through a user-friendly web interface.

Keep in mind that the instructions provided here assume a basic setup. For production environments, it's recommended to secure the Portainer instance, such as by using HTTPS and setting up authentication. Refer to the [Portainer documentation](https://documentation.portainer.io/) for more advanced configurations and security considerations.


### Configuring Nginx as Reverse proxy

1. Edit Nginx Configuration

    ```bash
    sudo vi /etc/nginx/sites-available/arpansahu
    ```

2. Add this server configuration

    ```bash
    server {
        listen         80;
        server_name    portainer.arpansahu.me;
        # force https-redirects
        if ($scheme = http) {
            return 301 https://$server_name$request_uri;
            }

        location / {
            proxy_pass              http://0.0.0.0:9998;
            proxy_set_header        Host $host;
            proxy_set_header    X-Forwarded-Proto $scheme;
        }

        listen 443 ssl; # managed by Certbot
        ssl_certificate /etc/letsencrypt/live/arpansahu.me/fullchain.pem; # managed by Certbot
        ssl_certificate_key /etc/letsencrypt/live/arpansahu.me/privkey.pem; # managed by Certbot
        include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
        ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
    }
    ```

3. Test the Nginx Configuration

    ```bash
    sudo nginx -t
    ```

4. Reload Nginx to apply the new configuration

    ```bash
    sudo systemctl reload nginx
    ```

### Running Portainer Agent 

1. Run this command to start the portainer agent docker container

    ```bash
        docker run -d -p 9995:9001 \
        --name portainer_agent \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /var/lib/docker/volumes:/var/lib/docker/volumes \
        portainer/agent:2.19.5
    ```

2. Configuring Nginx as Reverse proxy

    1. Edit Nginx Configuration

    ```bash
    sudo vi /etc/nginx/sites-available/arpansahu
    ```

    2. Add this server configuration

        ```bash
        server {
            listen         80;
            server_name    portainer-agent.arpansahu.me;
            # force https-redirects
            if ($scheme = http) {
                return 301 https://$server_name$request_uri;
                }

            location / {
                proxy_pass              http://0.0.0.0:9995;
                proxy_set_header        Host $host;
                proxy_set_header    X-Forwarded-Proto $scheme;
            }

            listen 443 ssl; # managed by Certbot
            ssl_certificate /etc/letsencrypt/live/arpansahu.me/fullchain.pem; # managed by Certbot
            ssl_certificate_key /etc/letsencrypt/live/arpansahu.me/privkey.pem; # managed by Certbot
            include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
            ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
        }
        ```

    3. Test the Nginx Configuration

        ```bash
        sudo nginx -t
        ```

    4. Reload Nginx to apply the new configuration

        ```bash
        sudo systemctl reload nginx
        ```
3. Adding Environment

    1. Go to environment ---> Choose Docker Standalone ----> Start Wizard

    2. Will show you a command same as step 1. Run this command to start the portainer agent docker container, this is default command we have modified ports although

        ```bash
            docker run -d -p 9001:9001 \    
            --name portainer_agent \
            --restart=always \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v /var/lib/docker/volumes:/var/lib/docker/volumes \
            portainer/agent:2.19.5
        ```

    3. Add Name, I have used docker-prod-env
    4. Add Environment address domain:port combination is needed in my case portainer-agent.arpansahu.me: 9995
    5. Click Connect

My Portainer can be accessed here : https://portainer.arpansahu.me/