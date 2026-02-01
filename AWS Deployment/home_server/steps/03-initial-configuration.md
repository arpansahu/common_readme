### Part 3: Initial Server Configuration

1. Login via SSH from another computer

    Find server IP:

    ```bash
    ip addr show
    ```

    From another computer:

    ```bash
    ssh username@SERVER_IP
    ```

2. Update system

    ```bash
    sudo apt update
    sudo apt upgrade -y
    ```

3. Install essential packages

    ```bash
    sudo apt install -y \
      curl \
      wget \
      git \
      htop \
      net-tools \
      vim \
      ca-certificates \
      gnupg \
      lsb-release \
      ufw \
      fail2ban
    ```

4. Configure firewall

    ```bash
    # Allow SSH
    sudo ufw allow 22/tcp

    # Allow HTTP/HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp

    # Enable firewall
    sudo ufw enable

    # Check status
    sudo ufw status
    ```

5. Configure Fail2Ban (SSH protection)

    ```bash
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
    ```

6. Set static local IP

    Find network interface name:

    ```bash
    ip addr show
    ```

    Edit netplan configuration:

    ```bash
    sudo vi /etc/netplan/00-installer-config.yaml
    ```

    Configure static IP:

    ```yaml
    network:
      version: 2
      renderer: networkd
      ethernets:
        enp0s3:  # Your interface name
          dhcp4: no
          addresses:
            - 192.168.1.100/24  # Choose available IP
          routes:
            - to: default
              via: 192.168.1.1  # Your router IP
          nameservers:
            addresses:
              - 8.8.8.8
              - 8.8.4.4
    ```

    Apply configuration:

    ```bash
    sudo netplan apply
    ```

7. Configure SSH key authentication (more secure)

    On your local computer:

    ```bash
    # Generate SSH key if you don't have one
    ssh-keygen -t ed25519 -C "your_email@example.com"

    # Copy public key to server
    ssh-copy-id username@192.168.1.100
    ```

    On server, disable password authentication:

    ```bash
    sudo vi /etc/ssh/sshd_config
    ```

    Set:

    ```bash
    PasswordAuthentication no
    PubkeyAuthentication yes
    ```

    Restart SSH:

    ```bash
    sudo systemctl restart sshd
    ```

