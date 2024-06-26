### Installing Harbor

1. **Download Harbor:**
   Go to the Harbor releases page and download the latest offline installer tarball, e.g., harbor-offline-installer-<version>.tgz.
   Alternatively, you can use wget to download it directly:

    ```bash
    wget https://github.com/goharbor/harbor/releases/download/v2.4.2/harbor-offline-installer-v2.4.2.tgz
    ```

2. **Extract the tarball:**

    ```bash
    tar -zxvf harbor-offline-installer-<version>.tgz
    cd harbor
    ```

3. **Configure Harbor:**
    Note: I am having multiple projects running in single machine and 1 nginx is handling subdomains and domain arpansahu.me. Similarly i want my harbor to be accessible 
    from harbor.arpansahu.me. 

    1.	Copy and edit the configuration file:

        ```bash
        cp harbor.yml.tmpl harbor.yml
        vi harbor.yml
        ```

    2. Edit harbor.yml 
        ```bash
        # Configuration file of Harbor

        # The IP address or hostname to access admin UI and registry service.
        # DO NOT use localhost or 127.0.0.1, because Harbor needs to be accessed by external clients.
        hostname: harbor.arpansahu.me

        # http related config
        http:
        # port for http, default is 80. If https enabled, this port will redirect to https port
        port: 8081
        # https related config
        https:
        # https port for harbor, default is 443
        port: 8443
        # The path of cert and key files for nginx
        certificate: /etc/letsencrypt/live/arpansahu.me/fullchain.pem 
        private_key: /etc/letsencrypt/live/arpansahu.me/privkey.pem


        .......
        more lines
        .......
        ```

        There are almost 250 lines of code in this yml file but we have to make sure to edit this much configuration particularly 
        default http port is 80 and https port is 443 since default harbor docker-compose.yml have nginx setup also. But we have our own nginx
        thats why we will change these both ports to available free port on the machine. I picked 8081 for http and 8443 for https. You can choose accordingly.


    3. Edit harbor.yml 

        ```bash
        [HARBOR DOCKER COMPOSE]
        ```

       

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
