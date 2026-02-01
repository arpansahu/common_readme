### Part 2: Ubuntu Server Installation

1. Download Ubuntu Server 22.04 LTS

    Visit: https://ubuntu.com/download/server

    Download the ISO (approximately 2GB)

2. Create bootable USB

    **On macOS:**

    ```bash
    # Find USB device
    diskutil list

    # Unmount USB (replace diskN with your disk)
    diskutil unmountDisk /dev/diskN

    # Write ISO to USB
    sudo dd if=ubuntu-22.04-live-server-amd64.iso of=/dev/rdiskN bs=1m
    ```

    **On Windows:**
    - Use Rufus: https://rufus.ie/
    - Select Ubuntu Server ISO
    - Click Start

    **On Linux:**

    ```bash
    # Find USB device
    lsblk

    # Write ISO (replace sdX with your device)
    sudo dd if=ubuntu-22.04-live-server-amd64.iso of=/dev/sdX bs=4M status=progress
    sudo sync
    ```

3. Boot from USB

    - Insert USB into laptop/desktop
    - Restart and press F2/F12/Delete (varies by manufacturer)
    - Select USB boot option

4. Install Ubuntu Server

    Follow installation wizard:

    - Language: English
    - Keyboard: Your layout
    - Network: Configure Ethernet (DHCP for now)
    - Storage: Use entire disk
    - Profile Setup:
      - Name: Your name
      - Server name: homeserver
      - Username: Choose username
      - Password: Strong password
    - SSH Setup: Install OpenSSH server
    - Featured Server Snaps: Skip for now

5. Complete installation and reboot

    Remove USB when prompted, then:

    ```bash
    sudo reboot
    ```

