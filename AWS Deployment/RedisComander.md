## Redis Commander

Redis Commander is a web-based management tool for Redis databases. It provides a user-friendly interface to interact with Redis, making it easier to manage and monitor your Redis instances.

### Installing Redis Commander

1. Installation:
    You can install redis-commander globally using npm (Node Package Manager) with the following command:

    ```bash
    npm install -g redis-commander
    ```

2. Run

    ```bash
    redis-commander --redis-host your-redis-server-ip --redis-port your-redis-port --redis-password your-redis-password --port 9996
    ```

### Serving with Nginx, as well password protecting Redis Commander

Redis Commander d'ont have native password protection enabled

1. Create a Basic Authentication File
    Use the htpasswd utility to create a username and password combination. Replace your_username with your desired username.

    ```bash
    sudo htpasswd -c /etc/nginx/.htpasswd your_username
    ```

    You’ll be prompted to enter a password.

2. Creating Server Block in Nginx config file

    ```bash
    sudo vi /etc/nginx/sites-available/arpansahu
    ```

3. Add this server block to it.

    ```bash
    server {
        listen         80;
        server_name    redis.arpansahu.me;
        # force https-redirects
        if ($scheme = http) {
            return 301 https://$server_name$request_uri;
            }

        location / {
            proxy_pass              http://127.0.0.1:9996;
            proxy_set_header        Host $host;
            proxy_set_header    X-Forwarded-Proto $scheme;
            auth_basic "Restricted Access";
            auth_basic_user_file /etc/nginx/.htpasswd;
        }

        listen 443 ssl; # managed by Certbot
        ssl_certificate /etc/letsencrypt/live/arpansahu.me/fullchain.pem; # managed by Certbot
        ssl_certificate_key /etc/letsencrypt/live/arpansahu.me/privkey.pem; # managed by Certbot
        include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    }
    ```

4. Test the Nginx Configuration

    ```bash
    sudo nginx -t
    ```
    
5. Reload Nginx to apply the new configuration

    ```bash
    sudo systemctl reload nginx
    ```

### Running Redis Commander in background Using pm2

1.	Install pm2 globally (if not already installed):

    ```bash
    npm install -g pm2
    ```


2. Start redis-commander with pm2:

    ```bash
    pm2 start redis-commander --name redis-commander -- --port 9996 --redis-host your-redis-server-ip --redis-port your-redis-port --redis-password your-redis-password
    ```

    This starts redis-commander with pm2 and names the process “redis-commander.”

3. 	Optionally, you can save the current processes to ensure they restart on system reboot:

    ```bash
    pm2 save
    ```

Now, redis-commander is running in the background managed by pm2. You can view its status, logs, and manage it using pm2 commands. For example:

4. View the status:

    ```bash
    pm2 status  
    ```

    Stop the process:

    ```bash
    pm2 stop redis-commander
    ```

    Restart the process:

    ```bash
    pm2 restart redis-commander
    ```

    View logs:

    ```bash
    pm2 logs redis-commander
    ```

5. Using nohup 

    The nohup command is designed to ignore the hangup (HUP) signal, allowing a command to continue running even after the user who initiated the command logs out or the terminal is closed. The message “ignoring input and appending output to ‘nohup.out’” is a standard message indicating that the command’s output is being redirected to a file named nohup.out in the current directory.

    ```bash
    nohup redis-commander --redis-host 0.0.0.0 --redis-port 6379 --redis-password redisKesar302 --port 9996 > redis-commander.log 2>&1 &
    ```

My Redis Commander can be accessed here : https://redis.arpansahu.me/
