## Redis Server

Redis is versatile and widely used for its speed and efficiency in various applications. Its ability to serve different roles, such as caching, real-time analytics, and pub/sub messaging, makes it a valuable tool in many technology stacks.

### Installing Redis and Setting Up Authentication


1. Step 1: Install Redis on Ubuntu

   1. **Update your package list:**
      ```sh
      sudo apt update
      ```

   2. **Install Redis:**
      ```sh
      sudo apt install redis-server
      ```

   3. **Start and enable Redis:**
      ```sh
      sudo systemctl start redis
      sudo systemctl enable redis
      ```

2. Step 2: Configure Redis

   1. **Open the Redis configuration file:**
      ```sh
      sudo vi /etc/redis/redis.conf
      ```

   2. **Change the host to 0.0.0.0:**
      Find the line with `bind 127.0.0.1 ::1` and change it to:
      ```
      bind 0.0.0.0
      ```

   3. **Set up authentication:**
      Find the line with `# requirepass foobared` and uncomment it. Replace `foobared` with your desired password:
      ```
      requirepass your_secure_password
      ```

   4. **Save and exit the editor** (`esc + :wq + enter` in vi).

   5. **Restart Redis to apply the changes:**
      ```sh
      sudo systemctl restart redis
      ```

3. Step 3: Verify Configuration

   1. **Connect to Redis using the CLI:**
      ```sh
      redis-cli
      ```

   2. **Authenticate with your password:**
      ```sh
      AUTH your_secure_password
      ```

   3. **Check the connection:**
      ```sh
      PING
      ```
      You should receive a response:
      ```
      PONG
      ```

   4. **Verify the binding to 0.0.0.0:**
      ```sh
      sudo netstat -tulnp | grep redis
      ```
      You should see Redis listening on `0.0.0.0:6379`.

4. Step 4: Connecting to Redis

   1. **Connect to Redis using the CLI from a remote host:**
      ```sh
      redis-cli -h arpansahu.me -p 6379 -a your_secure_password
      ```

## Note: If you want to use SSL connection

1. Open the Redis configuration file:
    ```sh
    sudo vi /etc/redis/redis.conf
    ```

2. Add the following configuration:
    ```
    tls-port 6379
    port 0

    tls-cert-file /path/to/redis.crt
    tls-key-file /path/to/redis.key
    tls-dh-params-file /path/to/dhparam.pem

    tls-auth-clients no
    ```

Mostly Redis is used as cache and we want it to be super fast; hence, we are not putting it behind a reverse proxy like Nginx, similar to PostgreSQL.

Mostly redis is used as cache and we want it to be super fast hence we are not putting it behind reverse proxy e.g. nginx same as postgres

Also one more thing redis by default don't support ssl connections even if u use ssl

redis server can be accessed

```bash
redis-cli -h arpansahu.me -p 6379 -a password_required
```