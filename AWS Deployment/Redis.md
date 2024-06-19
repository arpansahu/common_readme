### Installing Redis

1. **Create a Docker Volume for Portainer Data (optional but recommended):**
   This step is optional but recommended as it allows you to persist Portainer's data across container restarts.

    ```bash
    docker volume create portainer_data
    ```

2. **Run Portainer Container:**
   Run the Portainer container using the following command. Replace `/var/run/docker.sock` with the path to your Docker socket if it's in a different location.

    ```bash
    docker run -d -p 0.0.0.0:9998:9000 -p 9444:8000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
    to use it in nginx server configuration
    ```

   This command pulls the Portainer Community Edition image from Docker Hub, creates a persistent volume for Portainer data, and starts the Portainer container. The `-p 9000:9000` option maps Portainer's web interface to port 9000 on your host.

3. **Access Portainer UI:**
   Open your web browser and go to `http://localhost:9000` (or replace `localhost` with your server's IP address if you are using a remote server). You will be prompted to set up an admin user and password.

4. **Connect Portainer to the Docker Daemon:**
   On the Portainer setup page, choose the "Docker" environment, and connect Portainer to the Docker daemon. You can usually use the default settings (`unix:///var/run/docker.sock` for the Docker API endpoint).

5. **Complete Setup:**
   Follow the on-screen instructions to complete the setup process. You may choose to deploy a local agent for better performance, but it's not required for basic functionality.

Once the setup is complete, you should have access to the Portainer dashboard, where you can manage and monitor your Docker containers, images, volumes, and networks through a user-friendly web interface.

Keep in mind that the instructions provided here assume a basic setup. For production environments, it's recommended to secure the Portainer instance, such as by using HTTPS and setting up authentication. Refer to the [Portainer documentation](https://documentation.portainer.io/) for more advanced configurations and security considerations.

Note: if u want to use ssl connection you can 

/etc/redis/redis.conf open this file and 

tls-port 6379
port 0

tls-cert-file /path/to/redis.crt
tls-key-file /path/to/redis.key
tls-dh-params-file /path/to/dhparam.pem

tls-auth-clients no

Add this configuration 

Mostly redis is used as cache and we want it to be super fast hence we are not putting it behind reverse proxy e.g. nginx same as postgres

Also one more thing redis by default don't support ssl connections even if u use ssl