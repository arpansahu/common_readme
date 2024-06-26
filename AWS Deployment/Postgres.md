## Postgresql Server

IT would be a nightmare to have your own vps to save cost and not hosting your own postgresql server.

postgresql_server can be access accessed

### Installing PostgreSql

1. Update the package list to make sure you have the latest information

    ```bash
    sudo apt update
    ```

2. Install the PostgreSQL package

    ```bash
    sudo apt install postgresql postgresql-contrib
    ```

3. PostgreSQL should now be installed on your server. By default, PostgreSQL creates a user named `postgres` with administrative privileges. You can switch to this user to perform administrative tasks:

    ```bash
    sudo -i -u postgres
    ```

4. Access the PostgreSQL interactive terminal by running:

    ```bash
    psql
    ```

5. Set a password for the `postgres` user:

    ```sql
    ALTER USER postgres WITH PASSWORD 'your_password';
    ```

   Replace `'your_password'` with the desired password.

6. Exit the PostgreSQL shell:

    ```sql
    \q
    ```

7. Exit the `postgres` user session:

    ```bash
    exit
    ```

Now, PostgreSQL is installed on your Ubuntu server. You can access the PostgreSQL database by logging in with the `postgres` user and the password you set.

Remember to configure your PostgreSQL server according to your security needs, such as modifying the `pg_hba.conf` file to control access, setting up SSL for secure connections, and configuring other PostgreSQL settings as required for your environment.


## Configuring Postgresql

1. open postgresql.conf file

    ```bash
    sudo vi /etc/postgresql/14/main/postgresql.conf
    ```
     
    14 is the version which i have installed your version can be different

2. Find the listen_addresses line and set it to:

    ```bash
    listen_addresses = 'localhost'
    ```

    Now the thing is if u don't want to serve it using nginx u can also set it to * all so that database can be connected from any where

3. 	Edit pg_hba.conf to allow connections:

    ```bash
    sudo nano /etc/postgresql/14/main/pg_hba.conf
    ```

    14 is the version which i have installed your version can be different

4. 	Add the following line in the end:

    ```bash
    host    all             all             127.0.0.1/32            md5
    ```

    if u want to use without nginx

    ```bash
    host    all             all             0.0.0.0/0            md5
    ```

    I have added both 

5. Restart PostgreSQL to apply changes:

    ```bash
    sudo systemctl restart postgresql
    ```

## Configuring Nginx as Reverse proxy

Note: In previous steps we have already seen how to setup the reverse proxy with Nginx for Django projects and installation process and everything

1.	Install the nginx-extras package to support the stream module:

    ```bash
    sudo apt install nginx-extras
    ````

2.	Add a stream configuration file for the PostgreSQL stream:

    ```bash
    sudo vi /etc/nginx/nginx.conf
    ```

    1.	Add the following configuration:

    ```bash
    stream {
        upstream postgresql_upstream {
            server 127.0.0.1:5432;  # PostgreSQL server
        }

        server {
            listen 9550 ssl;  # Use SSL on port 443
            proxy_pass postgresql_upstream;

            ssl_certificate /etc/letsencrypt/live/arpansahu.me/fullchain.pem;  # SSL certificate
            ssl_certificate_key /etc/letsencrypt/live/arpansahu.me/privkey.pem;  # SSL certificate key
            ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;  # SSL DH parameters
            include /etc/letsencrypt/options-ssl-nginx.conf;  # SSL options

            proxy_timeout 600s;
            proxy_connect_timeout 600s;
        }
    }
    ```

    Since i have generated ssl certs already in nginx setup i am using those certificates here itself

    2. 	Test the Nginx Configuration:

    ```bash
    sudo nginx -t
    ```

    If error comes nginx: [emerg] "stream" directive is not allowed here in /etc/nginx/conf.d/postgresql.conf:1
    nginx: configuration file /etc/nginx/nginx.conf test failed    

    Follow these steps: 

        0.	Remove the custom configuration file:

            ```bash
            sudo rm /etc/nginx/conf.d/postgresql.conf
            ```

        1.	Open the main Nginx configuration file: 

            ```bash
            sudo nano /etc/nginx/nginx.conf
            ```

        2.	Add the Stream Block at the Appropriate Place
        Add the following stream block at the end of the nginx.conf file, or within the appropriate context:

            ```bash
            user www-data;
            worker_processes auto;
            pid /run/nginx.pid;
            include /etc/nginx/modules-enabled/*.conf;

            events {
                worker_connections 768;
            }

            http {
                sendfile on;
                tcp_nopush on;
                tcp_nodelay on;
                keepalive_timeout 65;
                types_hash_max_size 2048;

                include /etc/nginx/mime.types;
                default_type application/octet-stream;

                access_log /var/log/nginx/access.log;
                error_log /var/log/nginx/error.log;

                gzip on;
                gzip_disable "msie6";

                include /etc/nginx/conf.d/*.conf;
                include /etc/nginx/sites-enabled/*;
            }

            stream {
                upstream postgresql_upstream {
                    server 127.0.0.1:5432;  # PostgreSQL server
                }

                server {
                    listen 9550 ssl;  # Use SSL on port different 443
                    proxy_pass postgresql_upstream;

                    ssl_certificate /etc/letsencrypt/live/arpansahu.me/fullchain.pem;  # SSL certificate
                    ssl_certificate_key /etc/letsencrypt/live/arpansahu.me/privkey.pem;  # SSL certificate key
                    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;  # SSL DH parameters
                    include /etc/letsencrypt/options-ssl-nginx.conf;  # SSL options

                    proxy_timeout 600s;
                    proxy_connect_timeout 600s;
                }
            }
            ```
        
        3.	Test the Nginx Configuration
        
            ```bash
            sudo nginx -t
            ```

    3. Reload Nginx to apply the new configuration:

    ```bash
    sudo systemctl reload nginx
    ```

3. Testing connecting with postgres without ip and using domain

    ```bash
    psql "postgres://username:password@domain/database_name?sslmode=require"
    ```

    
```bash
psql "postgres://user:user_pass@arpansahu.me/database_name?sslmode=require"
```