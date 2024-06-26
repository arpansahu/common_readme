#### Installing the Nginx server

```bash
sudo apt-get install nginx
```

Starting Nginx and checking its status 

```bash
sudo systemctl start nginx
sudo systemctl status nginx
```

#### Modify DNS Configurations

Add these two records to your DNS Configurations

```bash
A Record	*	0.227.49.244 (public IP of ec2)	Automatic
A Record	@	0.227.49.244 (public IP of ec2)	Automatic
```

Note: now you will be able to see nginx running page if you open the public IP of the machine
IP
Make Sure your EC2 security Group have these entry inbound rules 

```bash
random-hash-id	IPv4	HTTP	TCP	80	0.0.0.0/0	–
```

Open a new Nginx Configuration file name can be anything i am choosing arpansahu since my domain is arpansahu.me. there is already a default configuration file but we will leave it like that only

```bash
sudo vi /etc/nginx/sites-available/arpansahu
```

paste this content in the above file

```bash
server_tokens               off;
access_log                  /var/log/nginx/supersecure.access.log;
error_log                   /var/log/nginx/supersecure.error.log;

server {
  server_name               arpansahu.me;        
  listen                    80;
  location / {
    proxy_pass              http://{ip_of_home_server/localhost}:8000;
    proxy_set_header        Host $host;
  }
}
```

This single Nginx File will be hosting all the multiple projects which I have listed before also.

Checking if the configurations file is correct

```bash
sudo service nginx configtest /etc/nginx/sites-available/arpansahu
```

Now you need to symlink this file to the sites-enabled directory:

```bash
cd /etc/nginx/sites-enabled
sudo ln -s ../sites-available/arpansahu
```

Restarting Nginx Server 

```bash
sudo systemctl restart nginx
```