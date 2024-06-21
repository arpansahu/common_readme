Previously This project was hosted on Heroku, but so I started hosting this and all other projects in a 
Single EC2 Machine, which cost me a lot, so now I have shifted all the projects to my own Home Server with 
Ubuntu 22.0 LTS Server, except for portfolio project at https://www.arpansahu.me along with Nginx 


Now there is an EC2 server running with an nginx server and arpansahu.me portfolio
Nginx forwarded https://arpansahu.me/ to the Home Server 

Multiple Projects are running inside dockers so all projects are dockerized.
You can refer to all projects at https://www.arpansahu.me/projects

Every project has a different port on which it runs predefined inside Dockerfile and docker-compose.yml

![EC2 and Home Server along with Nginx, Docker and Jenkins Arrangement](https://github.com/arpansahu/common_readme/blob/main/Images/ec2_and_home_server.png)

Note: Update as of Aug 2023, I have decided to make some changes to my lifestyle, and from now I will be constantly on the go
 from my experience with running a free EC2 server for arpansahu. me and nginx in it and then using another home server
 with all the other projects hosted, my experience was
      
 1. Downtime due to Broadband Service Provider Issues
 2. Downtime due to Weather Sometimes
 3. Downtime due to Machine Breakdown
 4. Downtime due to Power Cuts (even though I had an inverted battery setup for my room)
 5. Remotely it would be harder to fix these problems 

 and due to all these reasons I decided to shift all the projects to a single EC2 Server, at first I was using t2.medium which costs more than 40$ a month 
 then I switched to t2.small and it only costs you 15$ if we take pre-paid plans prices can be slashed much further. 

 Then again I shifted to Hostinger VPS which was more cost-friendly than EC2 Server. On Jan 2024

Now My project arrangements look something similar to this

![EC2 Sever along with Nginx, Docker and Jenkins Arrangement](https://github.com/arpansahu/common_readme/blob/main/Images/One%20Server%20Configuration%20for%20arpanahuone.png)
