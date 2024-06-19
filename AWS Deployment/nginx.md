Installing Nginx server

```
sudo apt-get install nginx
```

Starting Nginx and checking its status 

```
sudo systemctl start nginx
sudo systemctl status nginx
```

#### Modify DNS Configurations

Add these two records to your DNS Configurations
```
A Record	*	0.227.49.244 (public ip of ec2)	Automatic
A Record	@	0.227.49.244 (public ip of ec2)	Automatic
```

Note: now you will be able to see nginx running page if you open public ip of the machine

Make Sure your EC2 security Group have this entry inbound rules 

```
random-hash-id	IPv4	HTTP	TCP	80	0.0.0.0/0	–
```

Open a new Nginx Configuration file name can be anything i am choosing arpansahu since my domain is arpansahu.me. there is already a default configuration file but we will leave it like that only

```
sudo vi /etc/nginx/sites-available/arpansahu
```

paste this content in the above file

```
server_tokens               off;
access_log                  /var/log/nginx/supersecure.access.log;
error_log                   /var/log/nginx/supersecure.error.log;

server {
  server_name               arpansahu.me;        
  listen                    80;
  location / {
    proxy_pass              http://{ip_of_home_server}:8014;
    proxy_set_header        Host $host;
  }
}
```

Basically this single Nginx File will be hosting all the multiple projects which I have listed before also.

Checking if configurations fie is correct

```
sudo service nginx configtest /etc/nginx/sites-available/arpansahu
```

Now you need to symlink this file to the sites-enabled directory:

``` 
cd /etc/nginx/sites-enabled
sudo ln -s ../sites-available/arpansahu
```

Restarting Nginx Server 
```
sudo systemctl restart nginx
```

Now It's time to enable HTTPS for this server

### Step 3: Enabling HTTPS 

1. Base Domain:  Enabling https for base domain only or a single sub domain

    To allow visitors to access your site over HTTPS, you’ll need an SSL/TLS certificate that sits on your web server. Certificates are issued by a Certificate Authority (CA).We’ll use a free CA called Let’s Encrypt. To actually install the certificate, you can use the Certbot client, which gives you an utterly painless step-by-step series of prompts.
    Before starting with Certbot, you can tell Nginx up front to disable TLS version 1.0 and 1.1 in favor of versions 1.2 and 1.3. TLS 1.0 is end-of-life (EOL), while TLS 1.1 contained several vulnerabilities that were fixed by TLS 1.2. To do this, open the file /etc/nginx/nginx.conf. Find the following line:
    
    Open nginx.conf file end change ssl_protocols 
    
    ```
    sudo vi /etc/nginx/nginx.conf
    
    From ssl_protocols TLSv1 TLSv1.1 TLSv1.2; to ssl_protocols TLSv1.2 TLSv1.3;
    ```
    
    Use this command to verify if nginx.conf file is correct or not
    
    ```
    sudo nginx -t
    ```
    
    Now you’re ready to install and use Certbot, you can use snap to install Certbot:
    
    ```
    sudo snap install --classic certbot
    sudo ln -s /snap/bin/certbot /usr/bin/certbot
    ```
    
    Now installing certificate
    
    ```
    sudo certbot --nginx --rsa-key-size 4096 --no-redirect
    ```
    
    It will be asking for domain name then you can enter your base domain 
    I have generated ssl for arpansahu.me
    
    Then a few questions will be asked by them answer them all and done your ssl certificate will be generated
    
    Now These lines will be added to your # Nginx configuration: /etc/nginx/sites-available/arpansahu
    
    ```
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/www.supersecure.codes/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/www.supersecure.codes/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    ```
    
    Redirecting HTTP to HTTPS
    Open nginx configuration file  and make it like this

    ```
    sudo vi /etc/nginx/sites-available/arpansahu
    ```
    ```
    server_tokens               off;
    access_log                  /var/log/nginx/supersecure.access.log;
    error_log                   /var/log/nginx/supersecure.error.log;
     
    server {
      server_name               arpansahu.me;
      listen                    80;
      return                    307 https://$host$request_uri;
    }
    
    server {
    
      location / {
        proxy_pass              http://{ip_of_home_server}:8014;
        proxy_set_header        Host $host;
        
        listen 443 ssl; # managed by Certbot
        ssl_certificate /etc/letsencrypt/live/arpansahu.me/fullchain.pem; # managed by Certbot
        ssl_certificate_key /etc/letsencrypt/live/arpansahu.me/privkey.pem; # managed by Certbot
        include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
        ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
    }                          
    ``` 
    
    You can dry run and check weather it's renewal is working or not
    ```
    sudo certbot renew --dry-run
    ```
    
    Note: this process was for borcelle-crm.arpansahu.me and not for all subdomains.
        For all subdomains we will have to setup a wildcard ssl certificate


2. Enabling a Wildcard certificate

    Here we will enable ssl certificate for all subdomains at once
    
    Run following Command
    ```
    sudo certbot certonly --manual --preferred-challenges dns
    ```
    
    Again you will be asked domain name and here you will use *.arpansahu.me. and second domain you will use is
    arpansahu.me.
    
    Now, you should be having a question in your mind that why we are generating ssl for arpansahu.me separately.
    It's because Let's Encrupt does not include base doamin with wildcard certificates for subdomains.

    After running above command you will see a message similar to this
    
    ```
    Saving debug log to /var/log/letsencrypt/letsencrypt.log
    Please enter the domain name(s) you would like on your certificate (comma and/or
    space separated) (Enter 'c' to cancel): *.arpansahu.me
    Requesting a certificate for *.arpansahu.me
    
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    Please deploy a DNS TXT record under the name:
    
    _acme-challenge.arpansahu.me.
    
    with the following value:
    
    dpWCxvq3mARF5iGzSfaRNXwmdkUSs0wgsTPhSaX1gK4
    
    Before continuing, verify the TXT record has been deployed. Depending on the DNS
    provider, this may take some time, from a few seconds to multiple minutes. You can
    check if it has finished deploying with aid of online tools, such as the Google
    Admin Toolbox: https://toolbox.googleapps.com/apps/dig/#TXT/_acme-challenge.arpansahu.me.
    Look for one or more bolded line(s) below the line ';ANSWER'. It should show the
    value(s) you've just added.
   
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    Press Enter to Continue
    ```
   
    You will be given a dns challenge called ACME challenger you have to create a dns TXT record in DNS.
    Similar to below record.
    
    ```
    TXT Record	_acme-challenge	dpWCxvq3mARF5iGzSfaRNXwmdkUSs0wgsTPhSaX1gK4	5 Automatic
    ```
    
    Now, use this url to verify records are updated or not

    https://toolbox.googleapps.com/apps/dig/#TXT/_acme-challenge.arpansahu.me (arpansahu.me is domain)

    If its verified then press enter the terminal as mentioned above
    
    Then your certificate will be generated
    ```
    Successfully received certificate.
    Certificate is saved at: /etc/letsencrypt/live/arpansahu.me-0001/fullchain.pem            (use this in your nginx configuration file)
    Key is saved at:         /etc/letsencrypt/live/arpansahu.me-0001/privkey.pem
    This certificate expires on 2023-01-20.
    These files will be updated when the certificate renews.
    ```
    
    You can notice here, certificate generated is arpansahu.me-0001 and not arpansahu.me
    because we already generated a certificate named arpansahu.me
    
    So remember to delete it before generating this wildcard certificate
    using command

    ```
    sudo certbot delete
    ```
    
    Note: This certificate will not be renewed automatically. Auto-renewal of --manual certificates requires the use of an authentication hook script (--manual-auth-hook) but one was not provided. To renew this certificate, repeat this same certbot command before the certificate's expiry date.

3. Generating Wildcard SSL certificate and Automating its renewal

    1. Modify your ec2 inbound rules 
    
      ```
      –	sgr-0219f1387d28c96fb	IPv4	DNS (TCP)	TCP	53	0.0.0.0/0	–	
      –	sgr-01b2b32c3cee53aa9	IPv4	SSH	TCP	22	0.0.0.0/0	–
      –	sgr-0dfd03bbcdf60a4f7	IPv4	HTTP	TCP	80	0.0.0.0/0	–
      –	sgr-02668dff944b9b87f	IPv4	HTTPS	TCP	443	0.0.0.0/0	–
      –	sgr-013f089a3f960913c	IPv4	DNS (UDP)	UDP	53	0.0.0.0/0	–
      ```
    
   2. Install acme-dns Server

      * Create folder for acme-dns and change directory

        ```
         sudo mkdir /opt/acme-dns
         cd !$
        ```
      * Download and extract tar with acme-dns from GitHub

        ```
        sudo curl -L -o acme-dns.tar.gz \
        https://github.com/joohoi/acme-dns/releases/download/v0.8/acme-dns_0.8_linux_amd64.tar.gz
        sudo tar -zxf acme-dns.tar.gz
        ```
      * List files
        ```
        sudo ls
        ```
      * Clean Up
        ```
        sudo rm acme-dns.tar.gz
        ```
      * Create soft link
        ```
        sudo ln -s \
        /opt/acme-dns/acme-dns /usr/local/bin/acme-dns
        ```
      * Create a minimal acme-dns user
         ```
         sudo adduser \
         --system \	
         --gecos "acme-dns Service" \
         --disabled-password \
         --group \
         --home /var/lib/acme-dns \
         acme-dns
        ```
      * Update default acme-dns config compare with IP from the AWS console. CAn't bind to the public address need to use private one.
        ```
        ip addr
	  
        sudo mkdir -p /etc/acme-dns
	  
        sudo mv /opt/acme-dns/config.cfg /etc/acme-dns/
	  
        sudo vim /etc/acme-dns/config.cfg
        ```
      
      * Replace
        ```
        listen = "127.0.0.1:53” to listen = “private ip of the ec2 instance” 172.31.93.180:53(port will be 53)
 
        Similarly Edit other details mentioned below  

        # domain name to serve the requests off of
        domain = "auth.arpansahu.me"
        # zone name server
        nsname = "auth.arpansahu.me"
        # admin email address, where @ is substituted with .
        nsadmin = "admin@arpansahu.me"


        records = [
          # domain pointing to the public IP of your acme-dns server
           "auth.arpansahu.me. A 44.199.177.138. (public elastic ip)”,
          # specify that auth.example.org will resolve any *.auth.example.org records
           "auth.arpansahu.me. NS auth.arpansahu.me.”,
        ]
	
        [api]
        # listen ip eg. 127.0.0.1
        ip = "127.0.0.1”. (Changed)

        # listen port, eg. 443 for default HTTPS
        port = "8080" (Changed).         ——— we will use port 8090 because we will also use Jenkins which will be running on 8080 port
        # possible values: "letsencrypt", "letsencryptstaging", "cert", "none"
        tls = "none"   (Changed)

        ```
      * Move the systemd service and reload
        ```
        cat acme-dns.service
     
        sudo mv \
        acme-dns.service /etc/systemd/system/acme-dns.service
	  
        sudo systemctl daemon-reload
        ```
      * Start and enable acme-dns server
        ```
        sudo systemctl enable acme-dns.service
        sudo systemctl start acme-dns.service
        ```
      * Check acme-dns for posible errors
        ```
        sudo systemctl status acme-dns.service
        ```
      * Use journalctl to debug in case of errors
         ```
         journalctl --unit acme-dns --no-pager --follow
         ```
      * Create A record for your domain
         ```
         auth.arpansahu.me IN A <public-ip>
         ```
      * Create NS record for auth.arpansahu.me pointing to auth.arpansahu.me. This means, that auth.arpansahu.me is
        responsible for any *.auth.arpansahu.me records
        ```
        auth.arpansahu.me IN NS auth.arpansahu.me
        ```
      * Your DNS record will be looking like this
        ```
        A Record	auth	44.199.177.138	Automatic	
        NS Record	auth	auth.arpansahu.me.	Automatic
        ```
      * Test acme-dns server (Split the screen)
        ```
        journalctl -u acme-dns --no-pager --follow
        ```
      * From local host try to resolve random DNS record
        ```
        dig api.arpansahu.me
        dig api.auth.arpansahu.me
        dig 7gvhsbvf.auth.arpansahu.me
        ``` 
        
   3. Install acme-dns-client 
     ```
     sudo mkdir /opt/acme-dns-client
     cd !$
    
     sudo curl -L \
     -o acme-dns-client.tar.gz \
     https://github.com/acme-dns/acme-dns-client/releases/download/v0.2/acme-dns-client_0.2_linux_amd64.tar.gz
    
     sudo tar -zxf acme-dns-client.tar.gz
     ls
     sudo rm acme-dns-client.tar.gz
     sudo ln -s \
     /opt/acme-dns-client/acme-dns-client /usr/local/bin/acme-dns-client 
     ```
   4. Install Certbot
     ```
     cd
     sudo snap install core; sudo snap refresh core
     sudo snap install --classic certbot
     sudo ln -s /snap/bin/certbot /usr/bin/certbot
     ```
    Note: you can skip step4 if Certbot is already installed

    5. Get Letsencrypt Wildcard Certificate
       * Create a new acme-dns account for your domain and set it up
         ```
         sudo acme-dns-client register \
         -d arpansahu.me -s http://localhost:8090
         ```
         Note: When we edited acme-dns config file there we mentioned the port 8090 and thats why we are using this port here also
       * Creating Another DNS Entry 
         ```
         CNAME Record	_acme-challenge	e6ac0f0a-0358-46d6-a9d3-8dd41f44c7ec.auth.arpansahu.me.	Automatic
         ```
         Same as an entry is needed to be added to complete one time challenge as in previously we did.
       * Check the entry is added successfully or not
         ```
         dig _acme-challenge.arpansahu.me
         ```
       * Get wildcard certificate
         ```
         sudo certbot certonly \
         --manual \
         --test-cert \ 
         --preferred-challenges dns \ 
         --manual-auth-hook 'acme-dns-client' \ 
         -d ‘*.arpansahu.me’ -d arpansahu.me
         ```
         Note: Here we have to mention both the base and wildcard domain names with -d since let's encrypt don't provide base domain ssl by default in wildcard domain ssl
       *Verifying the certificate
         ```
         sudo openssl x509 -text -noout \
         -in /etc/letsencrypt/live/arpansahu.me/fullchain.pem
         ```
       * Renew certificate (test)
         ```
         sudo certbot renew \
         --manual \ 
         --test-cert \ 
         --dry-run \ 
         --preferred-challenges dns \
         --manual-auth-hook 'acme-dns-client'       
         ```
       * Renew certificate (actually)
         ```
         sudo certbot renew \
         --manual \
         --preferred-challenges dns \
         --manual-auth-hook 'acme-dns-client'       
         ```
       * Check the entry is added successfully or not
         ```
         dig _acme-challenge.arpansahu.me
         ```
    6. Setup Auto-Renew for Letsencrypt WILDCARD Certificate
       * Setup cronjob
         ```
         sudo crontab -e
         ```
       * Add following lines to the file
         ```
         0 */12 * * * certbot renew --manual --test-cert --preferred-challenges dns --manual-auth-hook 'acme-dns-client'
         ```