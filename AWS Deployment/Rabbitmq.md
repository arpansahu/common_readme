## RabbitMQ Server

RabbitMQ is a reliable and mature messaging and streaming broker, which is easy to deploy on cloud environments, on-premises, and on your local machine. It is currently used by millions worldwide.

### Installing RabbitMQ and Setting Up Authentication


1. Step 1: Update the System and Install the RabbitMQ 

   1. **Update your package list:**

      ```sh
        sudo apt-get update
        sudo apt-get upgrade -y
      ```

   2. **Install Erlang:**

      RabbitMQ requires Erlang, which can be installed from the Ubuntu repositories:

      ```sh
        sudo apt-get install -y erlang-nox
      ```

   3. **Install RabbitMQ:**
   
      Add the official RabbitMQ repository and install the RabbitMQ server:

      ```sh
        echo "deb https://dl.bintray.com/rabbitmq/debian $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/bintray.rabbitmq.list
        wget -O- https://dl.bintray.com/rabbitmq/Keys/rabbitmq-release-signing-key.asc | sudo apt-key add -
        sudo apt-get update
        sudo apt-get install -y rabbitmq-server
      ```

2. Step 2: Enable RabbitMQ Management Plugin

   1. **Open the Redis configuration file:**

      To manage RabbitMQ via a web UI, enable the management plugin:

      ```sh
        sudo rabbitmq-plugins enable rabbitmq_management
      ```

      The web UI will be available at `http://<your_server_ip>:15672/`.

3. Step 3: Configure RabbitMQ

   By default, RabbitMQ listens on localhost. Update the configuration to allow external access:

   1. **Connect to Redis using the CLI:**

      ```sh
      redis-cli
      ```

   2. **Authenticate with your password:**

      ```sh
      AUTH your_secure_password
      ```

   3. **Check the connection:**

      ```sh
      PING
      ```
      You should receive a response:
      ```
      PONG
      ```

   4. **Verify the binding to 0.0.0.0:**

      ```sh
        sudo netstat -tulnp | grep redis
      ```
      You should see Redis listening on `0.0.0.0:6379`.

4. Step 4: Connecting to Redis

   1. **Open the RabbitMQ configuration file:**

      ```sh
        sudo nano /etc/rabbitmq/rabbitmq.conf
      ```

   2. **Add the following configuration:**

      ```ini
        listeners.tcp.default = 5672
        management.listener.port = 15672
        management.listener.ip = 0.0.0.0
      ```
   3. **Open the firewall for RabbitMQ ports:**

      ```bash
        sudo ufw allow 5672/tcp
        sudo ufw allow 15672/tcp
      ```

   4. **Restart RabbitMQ to apply the changes:**
    
      ```
        sudo systemctl restart rabbitmq-server
      ```

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
        server_name    rabbitmq-admin.arpansahu.me;
        # force https-redirects
        if ($scheme = http) {
            return 301 https://$server_name$request_uri;
            }

        location / {
            proxy_pass              http://0.0.0.0:15672;
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

I have not enabled the whole RabbitMQ with SSL because it will make it slow.
RabbitMQ server can be accessed

```bash
curl -u admin:'password_required' -X GET http://arpansahu.me:15672/api/queues
```

RabbitMQ Admin Panel can be accessed at:

https://rabbitmq-admin.arpansahu.me
























