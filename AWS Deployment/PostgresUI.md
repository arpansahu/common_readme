# PGAdmin (PostgreSQl UI)

## Installing PgAdmin

1. **Create a Virtual Environment:**

   It's good practice to use virtual environments to isolate your project's dependencies. This helps avoid conflicts with system packages. You can create a virtual environment like this:

   ```bash
   python3 -m venv pgadmin_venv
   source pgadmin_venv/bin/activate
   ```

2. **Install pgAdmin 4:**

   Once you are in the virtual environment, install pgAdmin 4:

   ```bash
   pip install pgadmin4
   ```

   If you encounter any dependency conflicts, the virtual environment will help isolate the packages.

3. **Run pgAdmin 4:**

   After installing, try running pgAdmin 4:

   ```bash
   pgadmin4
   ```

By using a virtual environment, you avoid potential conflicts with system packages, and you can manage dependencies for pgAdmin 4 more effectively.

Remember to activate your virtual environment whenever you want to run pgAdmin 4:

```bash
source pgadmin_venv/bin/activate
pgadmin4
```

And deactivate it when you're done:

```bash
deactivate
```


This approach should help you manage the dependencies and resolve the version conflicts more effectively.

4. Edit Host from 127.0.0.1 tto 0.0.0.0

```bash
vi /root/pgadmin_venv/lib/python3.10/site-packages/pgadmin4/config.py
```


## Configuring Nginx as Reverse proxy

1. Edit Nginx Configuration

    ```bash
    sudo vi /etc/nginx/sites-available/arpansahu
    ```
2. Add this server configuration

```bash
server {
    listen         80;
    server_name    pgadmin.arpansahu.me;
    # force https-redirects
    if ($scheme = http) {
        return 301 https://$server_name$request_uri;
        }

    location / {
         proxy_pass              http://0.0.0.0:9997;
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