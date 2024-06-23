# Great Chat

[INTRODUCTION]

[AWS DEPLOYMENT INTRODUCTION]

[TECHNOLOGY QNA]

## Tech Stack

[DOC_AND_STACK]

## Demo

[DEMO]

## License

[MIT](https://choosealicense.com/licenses/mit/)


## Installation

[INSTALLATION]


[STATIC_FILES]


## Custom Django Management Commands

[DJANGO_COMMANDS]

## Readme Manager

[README of Readme Manager]

## Deployment on AWS EC2/ Home Server Ubuntu 22.0 LTS/ Hostinger VPS Server

[README of Intro]

### Step 1: Dockerize

[README of Docker Installation]

Now in your Git Repository

Create a file named Dockerfile with no extension and add following lines in it

```bash
[Dockerfile]
```

Create a file named docker-compose.yml and add following lines in it

```bash
[docker-compose.yml]
```

[DOCKER_END]

### Step2: Serving the requests from Nginx

[README of Nginx Setup]

After all these steps your Nginx configuration file located at /etc/nginx/sites-available/arpansahu will be looking similar to this

```bash
[NGINX_SERVER]
```

### Step 4: CI/CD using Jenkins

[README of Jenkins Setup]


* Now Create a file named Jenkinsfile at the root of Git Repo and add following lines to file

```bash
[Jenkinsfile]
```

[JENKINS_END]

## Postgresql Server

IT would be a nightmare to have your own vps to save cost and not hosting your own postgresql server.

For more information, see the [README of PostgreSql Server With Nginx Setup](https://github.com/arpansahu/common_readme/blob/main/AWS%20Deployment/Postgres.md).

postgresql_server can be access accessed

```bash
psql "postgres://user:user_pass@arpansahu.me/database_name?sslmode=require"
```

# Services on AWS EC2/ Home Server Ubuntu 22.0 LTS s

## PGAdmin4

pgAdmin 4 is a complete rewrite of pgAdmin, built using Python and Javascript/jQuery. A desktop runtime written in NWjs allows it to run standalone for individual users, or the web application code may be deployed directly on a web server for use by one or more users through their web browser. 

[README of PGAdmin4 Server With Nginx Setup]

My PGAdmin4 can be accessed here : https://pgadmin.arpansahu.me/

## Portainer
   
Portainer is a web UI to manage your docker, and kubernetes. Portainer consists of two elements, the Portainer Server, and the Portainer Agent. Both elements run as lightweight Docker containers on a Docker engine.

[README of Portainer Server With Nginx Setup]

My Portainer can be accessed here : https://portainer.arpansahu.me/

## Redis Server

Redis is versatile and widely used for its speed and efficiency in various applications. Its ability to serve different roles, such as caching, real-time analytics, and pub/sub messaging, makes it a valuable tool in many technology stacks.

[README of Redis Server Setup]

redis serve can be accessed

```bash
redis-cli -h arpansahu.me -p 6379 -a password_required
```

## Redis Commander

Redis Commander is a web-based management tool for Redis databases. It provides a user-friendly interface to interact with Redis, making it easier to manage and monitor your Redis instances.

[README of Redis Server Setup]

My Redis Commander can be accessed here : https://redis.arpansahu.me/

## MiniIo (Self hosted S3 Storage)

MinIO is a high-performance, distributed object storage system designed for large-scale data infrastructures. It is open-source and compatible with the Amazon S3 API, making it a popular choice for organizations looking for scalable, secure, and cost-effective storage solutions. 

[README of Redis Server Setup]

You can connect to my MiniIo Server using terminal 
```bash
  mc alias set myminio https://arpansahu.me api_key api_secret --api S3v4
  mc ls
```

Also there is a MiniIo UI Server which can be accessed here https://minioui.arpansahu.me/

## Documentation

[DOC_AND_STACK]

## Environment Variables

To run this project, you will need to add the following environment variables to your .env file

[env.example]


