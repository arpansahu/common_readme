# Dockerizing

Installing Docker on Home Server

Reference: https://docs.docker.com/engine/install/ubuntu/

1. Setting up the Repository
   1. Update the apt package index and install packages to allow apt to use a repository over HTTPS: 
       ```
       sudo apt-get update
    
       sudo apt-get install \
       ca-certificates \
       curl \
       gnupg \
       lsb-release
       ```
   2. Add Docker’s official GPG key:

       ```
       sudo mkdir -p /etc/apt/keyrings
    
       curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
       ```

   3. Use the following command to set up the repository:

       ```
       echo \
         "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
         $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
       ```
2. Install Docker Engine
    
   1. Update the apt package index:

      ```
       sudo apt-get update
      ```
    
      1. Receiving a GPG error when running apt-get update?

         Your default umask may be incorrectly configured, preventing detection of the repository public key file. Try granting read permission for the Docker public key file before updating the package index:
            ```
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            sudo apt-get update
            ```
   2. Install Docker Engine, containerd, and Docker Compose.

        ```
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
        ```
   3. Verify that the Docker Engine installation is successful by running the hello-world image:

        ```
         sudo docker run hello-world
        ```