### Installing Jenkins

Reference: https://www.jenkins.io/doc/book/installing/linux/

Jenkins requires Java to run, yet certain distributions don’t include this by default and some Java versions are incompatible with Jenkins.

There are multiple Java implementations which you can use. OpenJDK is the most popular one at the moment, we will use it in this guide.

Update the Debian apt repositories, install OpenJDK 11, and check the installation with the commands:

```bash
sudo apt update

sudo apt install openjdk-11-jre

java -version
openjdk version "11.0.12" 2021-07-20
OpenJDK Runtime Environment (build 11.0.12+7-post-Debian-2)
OpenJDK 64-Bit Server VM (build 11.0.12+7-post-Debian-2, mixed mode, sharing)
```

Long Term Support release

```bash
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins
```

Start Jenkins

```bash
sudo systemctl enable jenkins
```

You can start the Jenkins service with the command:

```bash
sudo systemctl start jenkins
```

You can check the status of the Jenkins service using the command:

```bash
sudo systemctl status jenkins
```

Now for serving the Jenkins UI from Nginx add the following lines to the Nginx file located at 
/etc/nginx/sites-available/arpansahu by running the following command

```bash
sudo vi /etc/nginx/sites-available/arpansahu
```

* Add these lines to it.

    ```bash
    server {
        listen         80;
        server_name    jenkins.arpansahu.me;
        # force https-redirects
        if ($scheme = http) {
            return 301 https://$server_name$request_uri;
            }
    
        location / {
             proxy_pass              http://{ip_of_home_server}:8080;
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

You can add all the server blocks to the same nginx configuration file
just make sure you place the server block for the base domain at the last

* To copy .env from the local server directory while building image

add Jenkins ALL=(ALL) NOPASSWD: ALL
inside /etc/sudoers file

and then put 

```bash
stage('Dependencies') {
            steps {
                script {
                    sh "sudo cp /root/env/project_name/.env /var/lib/jenkins/workspace/pipeline_project_name"
                }
            }
        }
```

* Also we Need to modify the Nginx Configuration File

1. Create a new configuration file: Create a new file in the Nginx configuration directory. The location of this directory varies depending on your  operating system and Nginx installation, but it’s usually found at /etc/nginx/sites-available/.

  ```bash
    touch /etc/nginx/sites-available/[PROJECT_NAME_DASH]
    vi /etc/nginx/sites-available/[PROJECT_NAME_DASH]
  ```

2.	Add the server block configuration: Copy and paste your server block configuration into this new file.

  We can have two configurations, one for docker and one for kubernetes deployment, out jenkins deployment file will handle it accordingly.

  1. Nginx for Docker Deployment 

    ```bash
        server {
            listen 80;
            server_name [DOMAIN_NAME];

            # Force HTTPS redirects
            if ($scheme = http) {
                return 301 https://$server_name$request_uri;
            }

            location / {
                proxy_pass http://0.0.0.0:[PROJECT_DOCKER_PORT];
                proxy_set_header Host $host;
                proxy_set_header X-Forwarded-Proto $scheme;

                # WebSocket support
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
            }

            listen 443 ssl; # managed by Certbot
            ssl_certificate /etc/letsencrypt/live/arpansahu.me/fullchain.pem; # managed by Certbot
            ssl_certificate_key /etc/letsencrypt/live/arpansahu.me/privkey.pem; # managed by Certbot
            include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
            ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
        }
    ```

  2. Nginx for Kubernetes Deployment 

    ```bash
        server {
            listen 80;
            server_name [DOMAIN_NAME];

            # Force HTTPS redirects
            if ($scheme = http) {
                return 301 https://$server_name$request_uri;
            }

            location / {
                proxy_pass http://<CLUSTER_IP_ADDRESS>:[PROJECT_NODE_PORT];
                proxy_set_header Host $host;
                proxy_set_header X-Forwarded-Proto $scheme;

                # WebSocket support
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
            }

            listen 443 ssl; # managed by Certbot
            ssl_certificate /etc/letsencrypt/live/arpansahu.me/fullchain.pem; # managed by Certbot
            ssl_certificate_key /etc/letsencrypt/live/arpansahu.me/privkey.pem; # managed by Certbot
            include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
            ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
        }
    ```

3.	Enable the new configuration: Create a symbolic link from this file to the sites-enabled directory.

    ```bash
      sudo ln -s /etc/nginx/sites-available/[PROJECT_NAME_DASH] /etc/nginx/sites-enabled/
    ```

4.	Test the Nginx configuration: Ensure that the new configuration doesn’t have any syntax errors.

  ```bash
    sudo nginx -t
  ```
  
5.	Reload Nginx: Apply the new configuration by reloading Nginx.

  ```bash
    sudo systemctl reload nginx
  ```

in Jenkinsfile-build to copy .env file into build directory

* Now Create a file named Jenkinsfile-build at the root of Git Repo and add following lines to file

```bash
[Jenkinsfile-build]
```

* Now Create a file named Jenkinsfile-deploy at the root of Git Repo and add following lines to file

```bash
[Jenkinsfile-deploy]
```