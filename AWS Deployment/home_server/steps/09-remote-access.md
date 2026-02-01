### Part 10: Remote Access Setup

1. Install and configure Tailscale VPN (recommended)

    ```bash
    curl -fsSL https://tailscale.com/install.sh | sh
    sudo tailscale up
    ```

    This provides secure remote access without exposing SSH to internet.

2. Alternative: Configure SSH for external access

    If you forwarded port 22, harden SSH:

    ```bash
    sudo vi /etc/ssh/sshd_config
    ```

    Set:

    ```bash
    Port 2222  # Change from 22
    PermitRootLogin no
    PasswordAuthentication no
    MaxAuthTries 3
    AllowUsers yourusername
    ```

    Update port forwarding in router to port 2222.

    Restart SSH:

    ```bash
    sudo systemctl restart sshd
    ```

