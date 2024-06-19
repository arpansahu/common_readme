Previously This project was hosted on Heroku, but so I started hosting this and all other projects in a 
Single EC2 Machine, which costed me a lot, so now I have shifted all the projects into my own Home Server with 
Ubuntu 22.0 LTS Server, except for portfolio project at https://www.arpansahu.me along with Nginx 


Now there is EC2 server running with a nginx server and arpansahu.me portfolio
Nginx forward https://arpansahu.me/ to Home Server 

Multiple Projects are running inside dockers so all projects are dockerized.
You can refer to all projects on https://www.arpansahu.me/projects

Every project have different port on which its running predefined inside Dockerfile and docker-compose.yml

![EC2 and Home Server along with Nginx, Docker and Jenkins Arrangement](https://github.com/arpansahu/common_readme/blob/main/Images/ec2_and_home_server.png)

Note: Update as of Aug 2023, I have decided to make some changes to my lifestyle, and from now i will be constantly on the go
      from my past experience with running free EC2 server for arpansahu.me and nginx in it and then using another home server
      with all the other projects hosted, my experience was
      
      1. Downtime due to Broadband Service Provider Issues
      2. Downtime due to Weather Sometimes
      3. Downtime due to Machine Breakdown
      4. Downtime due to Power Cuts (even though i had a inverted with battery setup for my room)
      5. Remotely it would be harder to fix these problems 

  and due to all these reasons i decided to shift all the projects to single EC2 Server, at first i was using t2.medium which costs more than 40$ a month 
  then i switched to t2.small and it only costs you 15$ and if we take pre paid plans prices can be slashed much further. 

  Then again i shifted to Hostinger VPS which was more cost friendly then EC2 Server. on Jan 2024

Now My project arrangements looks something similar to this

![EC2 Sever along with Nginx, Docker and Jenkins Arrangement](https://github.com/arpansahu/common_readme/blob/main/Images/One%20Server%20Configuration%20for%20arpanahuone.png)
