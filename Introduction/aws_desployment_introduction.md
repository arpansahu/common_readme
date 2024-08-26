-Deployed on AWS / Now in My Own Home Ubuntu Server LTS 22.0 / Hostinger VPS Server

1. Used Ubuntu 22.0 LTS
2. Used Nginx as a Web Proxy Server
3. Used Let's Encrypt Wildcard certificate 
4. Used Acme-dns server for automating renewal of wildcard certificates
5. Used docker/kubernetes to run inside a container since other projects are also running on the same server. Can be managed using Portainer and Kube Dashboard. Running at https://portainer.arpansahu.me and https://kube.arpansahu.me respectively.
6. Used Jenkins for CI/CD Integration Jenkins Server. Running at: https://jenkins.arpansahu.me
7. Used Self Hosted Redis VPS for redis which is not accessible outside AWS, Used Redis Server, hosted on Home Server itself as Redis on Home Server
8. Used PostgresSql Schema based Database, all projects are using single Postgresql. 
9. PostgresSQL is also hosted on VPS Server Itself.
10. Using MiniIo as self hosted S3 Storage Server. Running at: https://minio.arpansahu.me
11. Using Harbor as Self Hosted Docker Registry. Running at: https://harbor.arpansahu.me
12. Using Sentry for logging and debugging. Running at: https://arpansahu.sentry.io