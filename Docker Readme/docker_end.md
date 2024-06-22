### **What is Difference in Dockerfile and docker-compose.yml?**

A Dockerfile is a simple text file that contains the commands a user could call to assemble an image whereas Docker Compose is a tool for defining and running multi-container Docker applications.

Docker Compose define the services that make up your app in docker-compose.yml so they can be run together in an isolated environment. It gets an app running in one command by just running docker-compose up. Docker compose uses the Dockerfile if you add the build command to your project’s docker-compose.yml. Your Docker workflow should be to build a suitable Dockerfile for each image you wish to create, then use compose to assemble the images using the build command.

Running Docker 

```bash
docker compose up --build --detach 
```

--detach tag is for running the docker even if terminal is closed
if you remove this tag it will be attached to terminal, and you will be able to see the logs too

--build tag with docker compose up will force image to be rebuild every time before starting the container