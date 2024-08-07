
## Harbor (Self hosted Private Docker Registry)

Harbor is an open-source container image registry that secures images with role-based access control, scans images for vulnerabilities, and signs images as trusted. It extends the Docker Distribution by adding functionalities usually required by enterprise users, such as security, identity, and management.

### Installing Harbor

1. **Download Harbor:**
   Go to the Harbor releases page and download the latest offline installer tarball, e.g., harbor-offline-installer-<version>.tgz.
   Alternatively, you can use wget to download it directly:

    ```bash
    wget https://github.com/goharbor/harbor/releases/download/v2.4.2/harbor-offline-installer-v2.4.2.tgz
    ```

2. **Extract the tarball:**

    ```bash
    tar -zxvf harbor-offline-installer-v2.4.2.tgz
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
        port: 8601
        # https related config
        https:
        # https port for harbor, default is 443
        port: 8602
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


    3. Edit docker-compose.yml

        Here docker-compose.yml file only be available after running the below install command

        ```bash
            sudo ./install.sh --with-notary --with-trivy --with-chartmuseum
        ```

        Note: If docker compose is not available you need to install it

            1. Installing docker compose
                ```bash
                    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                ```
            2. Next, set the correct permissions so that the docker-compose command is executable:

                ```bash
                    sudo chmod +x /usr/local/bin/docker-compose
                ```
            
            3. To verify that the installation was successful, you can run:

                ```bash
                    docker-compose --version
                ```

        It might get success then you can see this file

        ```bash
            vi docker-compose.yml
        ```

        ```bash
        [HARBOR DOCKER COMPOSE]
        ```


        As you can see the ports we used in harbor.yml are configured here and nginx service have been removed.
        ports:
          - 8601:8080
          - 8602:8443
          - 4443:4443

4. **Run the Harbor install script:**
   
   ```bash
    sudo ./install.sh --with-notary --with-trivy --with-chartmuseum
   ```

5. **Complete Setup:**
   Follow the on-screen instructions to complete the setup process. You may choose to deploy a local agent for better performance, but it's not required for basic functionality.

Once the setup is complete, you should have access to the Portainer dashboard, where you can manage and monitor your Docker containers, images, volumes, and networks through a user-friendly web interface.

Keep in mind that the instructions provided here assume a basic setup. For production environments, it's recommended to secure the Portainer instance, such as by using HTTPS and setting up authentication. Refer to the [Portainer documentation](https://documentation.portainer.io/) for more advanced configurations and security considerations.


### Configuring Nginx as Reverse proxy

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

2. Add this server configuration

    ```bash
    server {
        listen         80;
        server_name    harbor.arpansahu.me;
        # force https-redirects
        if ($scheme = http) {
            return 301 https://$server_name$request_uri;
            }

        location / {
            proxy_pass              https://127.0.0.1:8443;
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

### Access Harbor UI

Harbor UI can be accessed here : https://portainer.arpansahu.me/

### Connecting Docker Registry 

Login to Docker Registry

You can connect to my Docker Registry  

```bash
    docker login harbor.arpansahu.me
```

### Pushing Image to Harbor Docker Registry

1. Tag Image

```bash
    docker tag image_name harbor.arpansahu.me/library/image_name:latest
```

2. Push Image

```bash
    docker push harbor.arpansahu.me/library/image_name:latest
```

### Create Image Retention Policy

Inside project, default project is library 
 
Go to >>> Library project
Go to >>> Policy
Click on >>> Add Policy

For the repositories == matching **
By artifact count or number of days == retain the most recently pulled # artifacts  Count = 2/3 no of last no of images 
tags == matching      Untagged artifacts = ticketed

This is one time task for entire project 

Same as below

![Add Retention Rule](https://github.com/arpansahu/common_readme/blob/main/AWS%20Deployment/harbor/retention_rule_add.png)

After adding rule schedule it as per requirement as below

![Add Retention Rule S](https://github.com/arpansahu/common_readme/blob/main/AWS%20Deployment/harbor/retention_rule_schedule.png)