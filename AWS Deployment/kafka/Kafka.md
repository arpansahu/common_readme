Kafka Server

Apache Kafka is a distributed event store and stream-processing platform. It is an open-source system developed by the Apache Software Foundation written in Java and Scala. The project aims to provide a unified, high-throughput, low-latency platform for handling real-time data feeds.

Installing Kafka, Zookeeper and AKHQ UI Setting Up Authentication

1. Update Your System

   Update your package list and upgrade existing packages:

      ```sh
      sudo apt update
      sudo apt upgrade -y Kafka
      ```

2. Install Java

   Kafka requires Java to run. Install OpenJDK 17:

      ```sh
      sudo apt install -y openjdk-17-jdk
      ```

   Verify the installation:


      ```sh
      java -version
      ```

   You should see output similar to:


      ```sh
      openjdk version "17.0.x" ...
      ```

3. Download and Install Kafka and Zookeeper

   ```sh
   # Update package lists
   sudo apt update

   # Install Java, as Kafka requires Java to run
   sudo apt install openjdk-11-jdk -y

   # Download Kafka
   wget https://archive.apache.org/dist/kafka/3.0.0/kafka_2.13-3.0.0.tgz

   # Extract the package
   tar -xzf kafka_2.13-3.0.0.tgz

   # Move Kafka files to a directory of your choice
   sudo mv kafka_2.13-3.0.0 /usr/local/kafka
   ````

4. Configure Zookeeper to be bind with localhost:

   Edit the zookeeper.properties file to make Zookeeper listen only on localhost:

   ```sh
   sudo vi /usr/local/kafka/config/zookeeper.properties
   ```

   Make sure 

   ```sh
      # Licensed to the Apache Software Foundation (ASF) under one or more
      # contributor license agreements.  See the NOTICE file distributed with
      # this work for additional information regarding copyright ownership.
      # The ASF licenses this file to You under the Apache License, Version 2.0
      # (the "License"); you may not use this file except in compliance with
      # the License.  You may obtain a copy of the License at
      #
      #    http://www.apache.org/licenses/LICENSE-2.0
      #
      # Unless required by applicable law or agreed to in writing, software
      # distributed under the License is distributed on an "AS IS" BASIS,
      # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
      # See the License for the specific language governing permissions and
      # limitations under the License.
      # the directory where the snapshot is stored.
      dataDir=/tmp/zookeeper
      # the port at which the clients will connect
      clientPort=2181
      clientPortAddress=localhost
      # disable the per-ip limit on the number of connections since this is a non-production config
      maxClientCnxns=0
      # Disable the adminserver by default to avoid port conflicts.
      # Set the port to something non-conflicting if choosing to enable this
      admin.enableServer=false
      # admin.serverPort=8080

      4lw.commands.whitelist=ruok,mntr,conf,srvr,stat
   ```
   looks like this

5. Configure Kafka to to localhost so that only internally can be accessed.

   Edit the server.properties file to make Kafka listen only on localhost for now:

   ```sh
   sudo vi /usr/local/kafka/config/server.properties
   ```

   and it should look like this 

   ```sh
      # Licensed to the Apache Software Foundation (ASF) under one or more
      # contributor license agreements.  See the NOTICE file distributed with
      # this work for additional information regarding copyright ownership.
      # The ASF licenses this file to You under the Apache License, Version 2.0
      # (the "License"); you may not use this file except in compliance with
      # the License.  You may obtain a copy of the License at
      #
      #    http://www.apache.org/licenses/LICENSE-2.0
      #
      # Unless required by applicable law or agreed to in writing, software
      # distributed under the License is distributed on an "AS IS" BASIS,
      # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
      # See the License for the specific language governing permissions and
      # limitations under the License.

      #
      # This configuration file is intended for use in ZK-based mode, where Apache ZooKeeper is required.
      # See kafka.server.KafkaConfig for additional details and defaults
      #

      ############################# Server Basics #############################

      # The id of the broker. This must be set to a unique integer for each broker.
      broker.id=0

      ############################# Socket Server Settings #############################

      # The address the socket server listens on. If not configured, the host name will be equal to the value of
      # java.net.InetAddress.getCanonicalHostName(), with PLAINTEXT listener name, and port 9092.
      #   FORMAT:
      #     listeners = listener_name://host_name:port
      #   EXAMPLE:
      #     listeners = PLAINTEXT://your.host.name:9092

      listeners=PLAINTEXT://localhost:9092


      # Listener name, hostname and port the broker will advertise to clients.
      # If not set, it uses the value for "listeners".
      #advertised.listeners=PLAINTEXT://your.host.name:9092

      # Maps listener names to security protocols, the default is for them to be the same. See the config documentation for more details
      #listener.security.protocol.map=PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL

      # The number of threads that the server uses for receiving requests from the network and sending responses to the network
      num.network.threads=3

      # The number of threads that the server uses for processing requests, which may include disk I/O
      num.io.threads=8

      # The send buffer (SO_SNDBUF) used by the socket server
      socket.send.buffer.bytes=102400

      # The receive buffer (SO_RCVBUF) used by the socket server
      socket.receive.buffer.bytes=102400

      # The maximum size of a request that the socket server will accept (protection against OOM)
      socket.request.max.bytes=104857600


      ############################# Log Basics #############################

      # A comma separated list of directories under which to store log files
      log.dirs=/tmp/kafka-logs

      # The default number of log partitions per topic. More partitions allow greater
      # parallelism for consumption, but this will also result in more files across
      # the brokers.
      num.partitions=1

      # The number of threads per data directory to be used for log recovery at startup and flushing at shutdown.
      # This value is recommended to be increased for installations with data dirs located in RAID array.
      num.recovery.threads.per.data.dir=1

      ############################# Internal Topic Settings  #############################
      # The replication factor for the group metadata internal topics "__consumer_offsets" and "__transaction_state"
      # For anything other than development testing, a value greater than 1 is recommended to ensure availability such as 3.
      offsets.topic.replication.factor=1
      transaction.state.log.replication.factor=1
      transaction.state.log.min.isr=1

      ############################# Log Flush Policy #############################

      # Messages are immediately written to the filesystem but by default we only fsync() to sync
      # the OS cache lazily. The following configurations control the flush of data to disk.
      # There are a few important trade-offs here:
      #    1. Durability: Unflushed data may be lost if you are not using replication.
      #    2. Latency: Very large flush intervals may lead to latency spikes when the flush does occur as there will be a lot of data to flush.
      #    3. Throughput: The flush is generally the most expensive operation, and a small flush interval may lead to excessive seeks.
      # The settings below allow one to configure the flush policy to flush data after a period of time or
      # every N messages (or both). This can be done globally and overridden on a per-topic basis.

      # The number of messages to accept before forcing a flush of data to disk
      #log.flush.interval.messages=10000

      # The maximum amount of time a message can sit in a log before we force a flush
      #log.flush.interval.ms=1000

      ############################# Log Retention Policy #############################

      # The following configurations control the disposal of log segments. The policy can
      # be set to delete segments after a period of time, or after a given size has accumulated.
      # A segment will be deleted whenever *either* of these criteria are met. Deletion always happens
      # from the end of the log.

      # The minimum age of a log file to be eligible for deletion due to age
      log.retention.hours=168

      # A size-based retention policy for logs. Segments are pruned from the log unless the remaining
      # segments drop below log.retention.bytes. Functions independently of log.retention.hours.
      #log.retention.bytes=1073741824

      # The maximum size of a log segment file. When this size is reached a new log segment will be created.
      #log.segment.bytes=1073741824

      # The interval at which log segments are checked to see if they can be deleted according
      # to the retention policies
      log.retention.check.interval.ms=300000

      ############################# Zookeeper #############################

      # Zookeeper connection string (see zookeeper docs for details).
      # This is a comma separated host:port pairs, each corresponding to a zk
      # server. e.g. "127.0.0.1:3000,127.0.0.1:3001,127.0.0.1:3002".
      # You can also append an optional chroot string to the urls to specify the
      # root directory for all kafka znodes.
      zookeeper.connect=localhost:2181

      # Timeout in ms for connecting to zookeeper
      zookeeper.connection.timeout.ms=18000


      ############################# Group Coordinator Settings #############################

      # The following configuration specifies the time, in milliseconds, that the GroupCoordinator will delay the initial consumer rebalance.
      # The rebalance will be further delayed by the value of group.initial.rebalance.delay.ms as new members join the group, up to a maximum of max.poll.interval.ms.
      # The default value for this is 3 seconds.
      # We override this to 0 here as it makes for a better out-of-the-box experience for development and testing.
      # However, in production environments the default value of 3 seconds is more suitable as this will help to avoid unnecessary, and potentially expensive, rebalances during application startup.
      group.initial.rebalance.delay.ms=0
   ```

6. Check for the availability of the ports required by zookeeper and kafka

   ```sh
      sudo lsof -i :9092
      sudo lsof -i :2181
   ```

7.  Start Zookeeper and Kafka

   Start Zookeeper first:

   ```sh
      cd /usr/local/kafka
      bin/zookeeper-server-start.sh config/zookeeper.properties
   ```

   In a new terminal, start Kafka:

   ```sh
      cd /usr/local/kafka
      bin/kafka-server-start.sh config/server.properties
   ```

8. Verifying the Setup

   To check if Zookeeper is running, you can use the following command to list the nodes Zookeeper manages:

   ```sh
      echo ruok | nc localhost 2181
   ```

   output is : imok

   To verify Kafka, you can create a test topic to ensure that it’s properly functioning. Run the following command to create a topic called test-topic:

   ```sh
      bin/kafka-topics.sh --create --topic test-topic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
   ```

   After creating the topic, you can list all the topics:

   ```sh
      bin/kafka-topics.sh --list --bootstrap-server localhost:9092
   ```

9. Now creating background tasks and run it using systemctl 

   Create a systemd Service for Zookeeper

   ```sh
      touch /etc/systemd/system/zookeeper.service
      sudo vi /etc/systemd/system/zookeeper.service
   ```

   paste this into it 

   ```sh
      [Unit]
      Description=Apache Zookeeper server
      Documentation=http://zookeeper.apache.org
      Requires=network.target
      After=network.target

      [Service]
      Type=simple
      ExecStart=/usr/local/kafka/bin/zookeeper-server-start.sh /usr/local/kafka/config/zookeeper.properties
      ExecStop=/usr/local/kafka/bin/zookeeper-server-stop.sh
      Restart=on-abnormal

      [Install]
      WantedBy=multi-user.target
   ```

   Create a systemd Service for Kafka

   ```sh
      touch /etc/systemd/system/kafka.service
      sudo vi /etc/systemd/system/kafka.service
   ```

   paste this into it 

   ```sh
      [Unit]
      Description=Apache Kafka Server
      Documentation=http://kafka.apache.org/documentation.html
      Requires=zookeeper.service
      After=zookeeper.service

      [Service]
      Type=simple
      ExecStart=/usr/local/kafka/bin/kafka-server-start.sh /usr/local/kafka/config/server.properties
      ExecStop=/usr/local/kafka/bin/kafka-server-stop.sh
      Restart=on-abnormal

      [Install]
      WantedBy=multi-user.target
   ```

10. Reload systemd and Start the Services

   After creating the service files, reload the systemd daemon so that it recognizes the new service files:
   
   ```sh
      sudo systemctl daemon-reload
   ```

   Now, you can start both Zookeeper and Kafka services in the background using systemctl:

   1. Start Zookeeper:

      ```sh
         sudo systemctl start zookeeper
      ```

      Enable Zookeeper to start automatically on boot:

      ```sh
         sudo systemctl enable zookeeper
      ```
      
   2. Start Kafka:

      ```sh
         sudo systemctl start kafka
      ```

      Enable Kafka to start automatically on boot:

      ```sh
         sudo systemctl enable kafka   
      ```
   
   3. Check the Status of the Services

      ```sh
         sudo systemctl status zookeeper
         sudo systemctl status kafka
      ```

11. Download and install AKHQ UI

   Create a directory 

   ```sh
      /root/akhq-kafka-ui
   ```

   Go to the created directory
   ```sh
      cd /root/akhq-kafka-ui
   ```

   Get the latest tar file from their github  release page: https://github.com/tchiotludo/akhq/releases
   
   ```sh
      wget https://github.com/tchiotludo/akhq/releases/download/0.25.1/akhq-0.25.1-all.jar -O akhq.jar
   ```

12. Create application.yaml file for akhq

   create and edit the file 

   ```sh
      touch application.yaml
      vi application.yaml
   ```

   and paste this into it

   ```sh
      micronaut:
      server:
         port: 9087  # Changed the port to avoid conflict
         cors:
            enabled: true
            configurations:
            all:
               allowedOrigins:
                  - http://localhost:9088

      security:
         enabled: true  # Micronaut security enabled to use authentication (OAuth2/Basic Auth)
         token:
            jwt:
            signatures:
               secret:
                  generator:
                  secret: "JWT_SECRET_KEY"  # Ensure this is a secure key (for JWT, if needed)

      akhq:

      connections:
         local:
            properties:
            bootstrap.servers: "localhost:9092"

      security:
         basic-auth:
            - username: admin
            password: "your_password_BCRYPT"  # BCRYPT hash of admin's password
            passwordHash: BCRYPT  # Specify BCRYPT for this user
            groups:
               - admin  # Assign the user to the admin group
            - username: reader
            password: "your_password_SHA"  # SHA-256 hash of reader's password
            passwordHash: SHA256  # Specify SHA-256 for this user
            groups:
               - reader  # Assign the user to the reader group

   ```

   Here yon can see there are two types of password supported SHA-256 and BCRYPT

   for generating SHA-256 use below command
   
   ```sh
      echo -n "your_password_SHA" | sha256sum
   ```
   and then use it 

   for generating BCRYPT follow this with help fo python
   
   ```sh
      pip install bcrypt 
   ```

   Run the below python code 
   ```sh
      import bcrypt

      password = "your_password_BCRYPT"
      # Force bcrypt to use the $2a$ prefix
      hashed_password = bcrypt.hashpw(password.encode(), bcrypt.gensalt(prefix=b'2a'))
      print(hashed_password.decode())  # Print the $2a$ version of the hash

   ```

   And for generating a random secure key for JWT run below command:

   ```sh
      openssl rand -base64 32
   ```

   it will give u randomly generated key like this : 0JgJkS8gstEK/PyKCCRZkYovx8kKDlfbPHS7vuBXS2k= use it for JWT_SECRET_KEY

13. Running the AKHQ ui 
   
   AKHQ server can be run using the tar file make sure you are at the dir /root/akhq-kafka-ui

   ```sh
      java -Dmicronaut.config.files=application.yml -jar akhq.jar
   ```

   This will start the AKHQ server at port 9087

   http://localhost:9087

14. Now creating background tasks and run it using systemctl 

   Create a systemd Service for AKHQ

   ```sh
      touch /etc/systemd/system/akhq-kafka-ui.service
      sudo vi /etc/systemd/system/akhq-kafka-ui.service
   ```

   paste this into it 

   ```sh
      [Unit]
      Description=Akhq Kafka UI Service
      After=network.target

      [Service]
      User=root
      ExecStart=/usr/bin/java -Dmicronaut.config.files=/root/akhq-kafka-ui/application.yml -jar /root/akhq-kafka-ui/akhq.jar
      SuccessExitStatus=143
      Restart=on-failure
      RestartSec=10

      [Install]
      WantedBy=multi-user.target
   ```

15. Reload systemd and Start the Services

   After creating the service files, reload the systemd daemon so that it recognizes the new service files:
   
   ```sh
      sudo systemctl daemon-reload
   ```

   Now, you can start both Zookeeper and Kafka services in the background using systemctl:

   1. Start Zookeeper:

      ```sh
         sudo systemctl start akhq-kafka-ui
      ```

      Enable Zookeeper to start automatically on boot:
      

   3. Check the Status of the Services

      ```sh
         sudo systemctl status akhq-kafka-ui
      ```

### Configuring Nginx as Reverse proxy

1. Edit Nginx Configuration

    ```bash
    sudo vi /etc/nginx/sites-available/services
    ```

    if /etc/nginx/sites-available/services does not exists

        1. Create a new configuration file: Create a new file in the Nginx configuration directory. The location of this directory varies depending on your  operating system and Nginx installation, but it’s usually found at /etc/nginx/sites-available/.

        ```bash
            touch /etc/nginx/sites-available/services
            vi /etc/nginx/sites-available/services
        ```


2. Add this server configuration

    ```bash

      # Map block to handle WebSocket upgrade
      map $http_upgrade $connection_upgrade {
         default upgrade;
         ''      close;
      }

      server {
         listen         80;
         server_name    akfq.arpansahu.me;

         # Redirect all HTTP traffic to HTTPS
         if ($scheme = http) {
            return 301 https://$server_name$request_uri;
         }

         location / {
               proxy_pass http://localhost:9087;
               proxy_set_header        Host $host;
               proxy_set_header    X-Forwarded-Proto $scheme;

               # WebSocket support
               proxy_http_version      1.1;
               proxy_set_header        Upgrade $http_upgrade;
               proxy_set_header        Connection $connection_upgrade;
         }

         # Disable HTTP/2 by ensuring http2 is not included in the listen directive
         listen 443 ssl; # managed by Certbot
         ssl_certificate           /etc/letsencrypt/live/arpansahu.me/fullchain.pem; # managed by Certbot
         ssl_certificate_key       /etc/letsencrypt/live/arpansahu.me/privkey.pem;   # managed by Certbot
         include                   /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
         ssl_dhparam               /etc/letsencrypt/ssl-dhparams.pem;       # managed by Certbot
      }
    ```

3. Test the Nginx Configuration

    ```bash
    sudo nginx -t
    ```

4. Reload Nginx to apply the new configuration

    ```bash
    sudo systemctl reload nginx
    ```
   
### Enabling SSL protection for kafka and enabling it to be accessible over the internet

1. Generating keystore and truststore

   1. Generating arpansahu_me_no_pass.p12 

      1. Decrypting privkey.pem by removing passphrase from it and saving it in privkey_no_passphrase.pem
         
         ```sh
            openssl rsa -in /etc/letsencrypt/live/arpansahu.me/privkey.pem -out /etc/letsencrypt/live/arpansahu.me/privkey_no_passphrase.pem
         ```

      2. Now we will generate arpansahu_me_no_pass.p12 using privkey_no_passphrase.pem

         ```sh
            openssl pkcs12 -export -in /etc/letsencrypt/live/arpansahu.me/fullchain.pem -inkey /etc/letsencrypt/live/arpansahu.me/privkey_no_passphrase.pem -out /etc/letsencrypt/live/arpansahu.me/arpansahu_me_no_pass.p12 -name kafka -CAfile /etc/letsencrypt/live/arpansahu.me/fullchain.pem -caname root
         ```
   2. Generating kafka.keystore.jks

      ```sh
         keytool -importkeystore -deststorepass TRUST_STORE_PASSWORD -destkeystore /etc/letsencrypt/live/arpansahu.me/kafka.keystore.jks -srckeystore /etc/letsencrypt/live/arpansahu.me/arpansahu_me_no_pass.p12 -srcstoretype PKCS12 -srcstorepass TRUST_STORE_PASSWORD -alias kafka
      ```

      NOTE: TRUST_STORE_PASSWORD  WILL BE USED EVERYWHERE SO MAKE SURE YOU TAKE A NOTE OF IT RELATED WITH JKS

   3. Test the generated kafka.keystore.jks is generated properly or not 

      ```sh
         keytool -list -keystore /etc/letsencrypt/live/arpansahu.me/kafka.keystore.jks
      ```

      Which will give output like this:
      
      ```sh
         Enter keystore password:
         Keystore type: PKCS12
         Keystore provider: SUN

         Your keystore contains 1 entry

         kafka, Sep 26, 2024, PrivateKeyEntry,
         Certificate fingerprint (SHA-256): 0B:7E:6B:CF:B3:5B:2F:39:7A:5B:8E:44:14:DE:0F:E4:9E:DF:58:2C:52:E5:3F:65:7B:DF:6E:D2:B0:01:D3:F4
      ```

      Then you know you have generated correct pks file for authentication


2. Updating the kafka server configuration
   
   Edit the server.properties file to make Kafka listen only on 0.0.0.0 making it available over the internet:

   ```sh
   sudo vi /usr/local/kafka/config/server.properties
   ```

   and it should look like this 
   ```sh
      # Licensed to the Apache Software Foundation (ASF) under one or more
      # contributor license agreements.  See the NOTICE file distributed with
      # this work for additional information regarding copyright ownership.
      # The ASF licenses this file to You under the Apache License, Version 2.0
      # (the "License"); you may not use this file except in compliance with
      # the License.  You may obtain a copy of the License at
      #
      #    http://www.apache.org/licenses/LICENSE-2.0
      #
      # Unless required by applicable law or agreed to in writing, software
      # distributed under the License is distributed on an "AS IS" BASIS,
      # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
      # See the License for the specific language governing permissions and
      # limitations under the License.

      #
      # This configuration file is intended for use in ZK-based mode, where Apache ZooKeeper is required.
      # See kafka.server.KafkaConfig for additional details and defaults
      #

      ############################# Server Basics #############################

      # The id of the broker. This must be set to a unique integer for each broker.
      broker.id=0

      ############################# Socket Server Settings #############################

      # The address the socket server listens on. If not configured, the host name will be equal to the value of
      # java.net.InetAddress.getCanonicalHostName(), with PLAINTEXT listener name, and port 9092.
      #   FORMAT:
      #     listeners = listener_name://host_name:port
      #   EXAMPLE:
      #     listeners = PLAINTEXT://your.host.name:9092

      #listeners=PLAINTEXT://localhost:9092


      # Enable listeners for SASL_SSL
      listeners=SASL_SSL://0.0.0.0:9093
      advertised.listeners=SASL_SSL://kafka.arpansahu.me:9093


      # SSL/TLS configuration
      ssl.keystore.location=/etc/letsencrypt/live/arpansahu.me/kafka.keystore.jks
      ssl.keystore.password=TRUST_STORE_PASSWORD
      ssl.key.password=TRUST_STORE_PASSWORD
      ssl.truststore.location=/etc/letsencrypt/live/arpansahu.me/kafka.keystore.jks
      ssl.truststore.password=TRUST_STORE_PASSWORD
      ssl.keystore.type=PKCS12

      # Note: when we generate jsk from letsencrypt generated ssl certificates then ssl.keystore.location can be same as ssl.truststore.location

      # Do not require client certificates
      ssl.client.auth=none

      # Supported SSL protocols
      ssl.enabled.protocols=TLSv1.2,TLSv1.3
      ssl.endpoint.identification.algorithm=https

      # Security configurations
      security.inter.broker.protocol=SASL_SSL
      sasl.mechanism.inter.broker.protocol=PLAIN
      sasl.enabled.mechanisms=PLAIN



      # Listener name, hostname and port the broker will advertise to clients.
      # If not set, it uses the value for "listeners".
      #advertised.listeners=PLAINTEXT://your.host.name:9092

      # Maps listener names to security protocols, the default is for them to be the same. See the config documentation for more details
      #listener.security.protocol.map=PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL

      # The number of threads that the server uses for receiving requests from the network and sending responses to the network
      num.network.threads=3

      # The number of threads that the server uses for processing requests, which may include disk I/O
      num.io.threads=8

      # The send buffer (SO_SNDBUF) used by the socket server
      socket.send.buffer.bytes=102400

      # The receive buffer (SO_RCVBUF) used by the socket server
      socket.receive.buffer.bytes=102400

      # The maximum size of a request that the socket server will accept (protection against OOM)
      socket.request.max.bytes=104857600


      ############################# Log Basics #############################

      # A comma separated list of directories under which to store log files
      log.dirs=/tmp/kafka-logs

      # The default number of log partitions per topic. More partitions allow greater
      # parallelism for consumption, but this will also result in more files across
      # the brokers.
      num.partitions=1

      # The number of threads per data directory to be used for log recovery at startup and flushing at shutdown.
      # This value is recommended to be increased for installations with data dirs located in RAID array.
      num.recovery.threads.per.data.dir=1

      ############################# Internal Topic Settings  #############################
      # The replication factor for the group metadata internal topics "__consumer_offsets" and "__transaction_state"
      # For anything other than development testing, a value greater than 1 is recommended to ensure availability such as 3.
      offsets.topic.replication.factor=1
      transaction.state.log.replication.factor=1
      transaction.state.log.min.isr=1

      ############################# Log Flush Policy #############################

      # Messages are immediately written to the filesystem but by default we only fsync() to sync
      # the OS cache lazily. The following configurations control the flush of data to disk.
      # There are a few important trade-offs here:
      #    1. Durability: Unflushed data may be lost if you are not using replication.
      #    2. Latency: Very large flush intervals may lead to latency spikes when the flush does occur as there will be a lot of data to flush.
      #    3. Throughput: The flush is generally the most expensive operation, and a small flush interval may lead to excessive seeks.
      # The settings below allow one to configure the flush policy to flush data after a period of time or
      # every N messages (or both). This can be done globally and overridden on a per-topic basis.

      # The number of messages to accept before forcing a flush of data to disk
      #log.flush.interval.messages=10000

      # The maximum amount of time a message can sit in a log before we force a flush
      #log.flush.interval.ms=1000

      ############################# Log Retention Policy #############################

      # The following configurations control the disposal of log segments. The policy can
      # be set to delete segments after a period of time, or after a given size has accumulated.
      # A segment will be deleted whenever *either* of these criteria are met. Deletion always happens
      # from the end of the log.

      # The minimum age of a log file to be eligible for deletion due to age
      log.retention.hours=168

      # A size-based retention policy for logs. Segments are pruned from the log unless the remaining
      # segments drop below log.retention.bytes. Functions independently of log.retention.hours.
      #log.retention.bytes=1073741824

      # The maximum size of a log segment file. When this size is reached a new log segment will be created.
      #log.segment.bytes=1073741824

      # The interval at which log segments are checked to see if they can be deleted according
      # to the retention policies
      log.retention.check.interval.ms=300000

      ############################# Zookeeper #############################

      # Zookeeper connection string (see zookeeper docs for details).
      # This is a comma separated host:port pairs, each corresponding to a zk
      # server. e.g. "127.0.0.1:3000,127.0.0.1:3001,127.0.0.1:3002".
      # You can also append an optional chroot string to the urls to specify the
      # root directory for all kafka znodes.
      zookeeper.connect=localhost:2181

      # Timeout in ms for connecting to zookeeper
      zookeeper.connection.timeout.ms=18000


      ############################# Group Coordinator Settings #############################

      # The following configuration specifies the time, in milliseconds, that the GroupCoordinator will delay the initial consumer rebalance.
      # The rebalance will be further delayed by the value of group.initial.rebalance.delay.ms as new members join the group, up to a maximum of max.poll.interval.ms.
      # The default value for this is 3 seconds.
      # We override this to 0 here as it makes for a better out-of-the-box experience for development and testing.
      # However, in production environments the default value of 3 seconds is more suitable as this will help to avoid unnecessary, and potentially expensive, rebalances during application startup.
      group.initial.rebalance.delay.ms=0
   ```

3. Creating JAAS configuration kafka_server_jaas.conf

   Create a dir at root as 

   ```sh
      mkdir /root/kafka
      cd /root/kafka
   ```

   Create the kafka_server_jaas.conf file and edit it 

   ```sh
      touch kafka_server_jaas.conf
      vi kafka_server_jaas.conf
   ```

   Add the following to the 

4. Again edit the systemd Service configuration for kafka

   Edit systemd Service for Kafka

   ```sh
      sudo vi /etc/systemd/system/kafka.service
   ```

   paste this into it 

   ```sh
      [Unit]
      Description=Apache Kafka Server
      Documentation=http://kafka.apache.org/documentation.html
      Requires=zookeeper.service
      After=zookeeper.service

      [Service]
      Type=simple
      Environment="KAFKA_OPTS=-Djava.security.auth.login.config=/root/kafka/kafka_server_jaas.conf"
      ExecStart=/usr/local/kafka/bin/kafka-server-start.sh /usr/local/kafka/config/server.properties
      ExecStop=/usr/local/kafka/bin/kafka-server-stop.sh
      Restart=on-abnormal

      [Install]
      WantedBy=multi-user.target
   ```

5. Reload systemd and Start the Services

   After creating the service files, reload the systemd daemon so that it recognizes the new service files:
   
   ```sh
      sudo systemctl daemon-reload
   ```

   Now, you can restart Kafka services in the background using systemctl:

   1. Restart Kafka:

      ```sh
         sudo systemctl restart kafka
      ```
   
   2. Check the Status of the Services

      ```sh
         sudo systemctl status kafka
      ```
   
6. Now modify AKHQ configuration application.yaml to support our ssl kafka

   Edit application.yaml

   ```sh
      vi /root/akhq-kafka-ui/application.yaml
   ```

   Add the below code to the application.yaml

   ```sh
      micronaut:
      server:
         port: 9087
         cors:
            enabled: true
            configurations:
            all:
               allowedOrigins:
                  - http://localhost:9088
      security:
         enabled: true
         token:
            jwt:
            signatures:
               secret:
                  generator:
                  secret: "JWT_SECRET_KEY"  # Replace with a secure secret

      akhq:
      connections:
         local:
            properties:
            bootstrap.servers: "kafka.arpansahu.me:9093"  # Ensure this matches the actual Kafka server address and port
            security.protocol: SASL_SSL
            sasl.mechanism: PLAIN
            sasl.jaas.config: org.apache.kafka.common.security.plain.PlainLoginModule required username="JAAS_USER" password="JAAS_PASSWORD";
            ssl.truststore.location: "/etc/letsencrypt/live/arpansahu.me/kafka.keystore.jks"  # Path to the truststore for SSL verification
            ssl.truststore.password: "TRUST_STORE_PASSWORD"

      security:
         basic-auth:
            - username: admin
            password: "your_password_BCRYPT"  # BCRYPT hash
            passwordHash: BCRYPT
            groups:
               - admin
   ```

   Now, you can restart Kafka services in the background using systemctl:

      1. Restart akhq-kafka-ui:

         ```sh
            sudo systemctl restart akhq-kafka-ui
         ```
      
      2. Check the Status of the Services

         ```sh
            sudo systemctl status akhq-kafka-ui
         ```


### Testing kafka connectivity using python 


1. Generating fullchain with CA file also

   1. Download the original fullchain.pem file from the server

      ```sh
         openssl s_client -connect kafka.arpansahu.me:9093 -CAfile fullchain.pem
      ```
   
   2. download isrgrootx1.pem of letsencrypt

      ```sh
         wget https://letsencrypt.org/certs/isrgrootx1.pem
      ```
   
   3. cat isrgrootx1.pem to fullchain.pem

      ```sh
         cat isrgrootx1.pem >> fullchain.pem
      ```

   4. Test the certificate against the domain

      ```sh
         openssl s_client -connect kafka.arpansahu.me:9093 -CAfile fullchain.pem
      ```

   5. Also test against itself

      ```sh
         openssl verify -CAfile fullchain.pem fullchain.pem\
      ```

2. Create a python file and install confluent-kafka

   ```sh
      touch kafka_test_connectivity.py
      pip install confluent-kafka
   ```

   Add the following code to the file

   ```sh
      from confluent_kafka.admin import AdminClient, NewTopic
      from confluent_kafka import KafkaException

      # Kafka admin client configuration
      admin_client = AdminClient({
         'bootstrap.servers': 'kafka.arpansahu.me:9093',
         'security.protocol': 'SASL_SSL',
         'sasl.mechanisms': 'PLAIN',
         'sasl.username': 'JAAS_USER',
         'sasl.password': 'JAAS_PASSWORD',
         'ssl.ca.location': 'fullchain.pem'
      })

      def create_topic(topic_name):
         new_topic = NewTopic(topic=topic_name, num_partitions=1, replication_factor=1)
         fs = admin_client.create_topics([new_topic])

         for topic, f in fs.items():
            try:
                  f.result()
                  print(f"Topic {topic} created successfully.")
            except KafkaException as e:
                  print(f"Failed to create topic {topic}: {e}")

      def list_topics():
         metadata = admin_client.list_topics(timeout=10)
         print("Available topics:")
         for topic in metadata.topics:
            print(topic)

      # Create a new topic
      create_topic('new-topic-python111')

      # List all available topics
      list_topics()
   ```