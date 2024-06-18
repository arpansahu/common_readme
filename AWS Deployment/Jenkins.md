# CI/CD with Jenkins

Installing Jenkins

Reference: https://www.jenkins.io/doc/book/installing/linux/

Jenkins requires Java in order to run, yet certain distributions don’t include this by default and some Java versions are incompatible with Jenkins.

There are multiple Java implementations which you can use. OpenJDK is the most popular one at the moment, we will use it in this guide.

Update the Debian apt repositories, install OpenJDK 11, and check the installation with the commands:

```
sudo apt update

sudo apt install openjdk-11-jre

java -version
openjdk version "11.0.12" 2021-07-20
OpenJDK Runtime Environment (build 11.0.12+7-post-Debian-2)
OpenJDK 64-Bit Server VM (build 11.0.12+7-post-Debian-2, mixed mode, sharing)
```

Long Term Support release

```
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins
```

Start Jenkins

```
sudo systemctl enable jenkins
```

You can start the Jenkins service with the command:

```
sudo systemctl start jenkins
```

You can check the status of the Jenkins service using the command:
```
sudo systemctl status jenkins
```

Now for serving the Jenkins UI from Nginx add these following lines to the Nginx file located at 
/etc/nginx/sites-available/arpansahu by running the following command

```
sudo vi /etc/nginx/sites-available/arpansahu
```

* Add these lines to it.

    ```
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
just make sure you place the server block for base domain at the last

* To copy .env from local server directory while buidling image

add Jenkins ALL=(ALL) NOPASSWD: ALL
inside /etc/sudoers file

and then put 

stage('Dependencies') {
            steps {
                script {
                    sh "sudo cp /root/env/project_name/.env /var/lib/jenkins/workspace/project_name"
                }
            }
        }

in jenkinsfile

* Now Create a file named Jenkinsfile at the root of Git Repo and add following lines to file

```
pipeline {
    agent { label 'local' }
    stages {
        stage('Dependencies') {
            steps {
                script {
                    sh "sudo cp /root/projectenvs/{project_name}/.env /var/lib/jenkins/workspace/{project_name}"
                }
            }
        }
        stage('Production') {
            steps {
                script {
                    sh "docker compose up --build --detach"
                }
            }
        }
    }
    post {
        success {
            sh """curl -s \
            -X POST \
            --user $MAIL_JET_API_KEY:$MAIL_JET_API_SECRET \
            https://api.mailjet.com/v3.1/send \
            -H "Content-Type:application/json" \
            -d '{
                "Messages":[
                        {
                                "From": {
                                        "Email": "$MAIL_JET_EMAIL_ADDRESS",
                                        "Name": "ArpanSahuOne Jenkins Notification"
                                },
                                "To": [
                                        {
                                                "Email": "$MY_EMAIL_ADDRESS",
                                                "Name": "Development Team"
                                        }
                                ],
                                "Subject": "${currentBuild.fullDisplayName} deployed succcessfully",
                                "TextPart": "Hola Development Team, your project ${currentBuild.fullDisplayName} is now deployed",
                                "HTMLPart": "<h3>Hola Development Team, your project ${currentBuild.fullDisplayName} is now deployed </h3> <br> <p> Build Url: ${env.BUILD_URL}  </p>"
                        }
                ]
            }'"""
        }
        failure {
            sh """curl -s \
            -X POST \
            --user $MAIL_JET_API_KEY:$MAIL_JET_API_SECRET \
            https://api.mailjet.com/v3.1/send \
            -H "Content-Type:application/json" \
            -d '{
                "Messages":[
                        {
                                "From": {
                                        "Email": "$MAIL_JET_EMAIL_ADDRESS",
                                        "Name": "ArpanSahuOne Jenkins Notification"
                                },
                                "To": [
                                        {
                                                "Email": "$MY_EMAIL_ADDRESS",
                                                "Name": "Developer Team"
                                        }
                                ],
                                "Subject": "${currentBuild.fullDisplayName} deployment failed",
                                "TextPart": "Hola Development Team, your project ${currentBuild.fullDisplayName} deployment failed",
                                "HTMLPart": "<h3>Hola Development Team, your project ${currentBuild.fullDisplayName} is not deployed, Build Failed </h3> <br> <p> Build Url: ${env.BUILD_URL}  </p>"
                        }
                ]
            }'"""
        }
    }
}
```

Note: agent {label 'local'} is used to specify which node will execute the jenkins job deployment. Basically there are two nodes in this project 
      One is my local Linux Server and Another is AWS EC2 machine where nginx is hosted there arpansahu.me my portfolio is also hosted is also hosted.
      So local linux server is labelled with 'local' are the project with this label will be executed in local machine node.


* Configure a Jenkins project from jenkins ui located at https://jenkins.arpansahu.me

Make sure to use Pipline project and name it whatever you want I have named it as great_chat

![Jenkins Project for borcelle CRM Configuration File](/great_chat-Config-Jenkins-.png)

In this above picture you can see credentials right? you can add your github credentials
from Manage Jenkins on home Page --> Manage Credentials

and add your GitHub credentials from there

* Add a .env file to you project using following command (This step is no more required stage('Dependencies'))

    ```
    sudo vi  /var/lib/jenkins/workspace/borcelle_crm_declarative_pipeline_project/.env
    ```

    Your workspace name may be different.

    Add all the env variables as required and mentioned in the Readme File.

* Add Global Jenkins Variables from Dashboard --> Manage --> Jenkins
  Configure System
 
  * MAIL_JET_API_KEY
  * MAIL_JET_API_SECRET
  * MAIL_JET_EMAIL_ADDRESS
  * MY_EMAIL_ADDRESS

Now you are good to go.