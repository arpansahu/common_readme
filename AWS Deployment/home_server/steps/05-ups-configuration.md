### Part 6: UPS Configuration

1. Connect UPS

    - Connect server to UPS
    - Connect UPS to power
    - Connect UPS to server via USB

2. Install NUT (Network UPS Tools)

    ```bash
    sudo apt install nut
    ```

3. Find UPS device

    ```bash
    sudo nut-scanner -U
    ```

4. Configure UPS driver

    ```bash
    sudo vi /etc/nut/ups.conf
    ```

    Add:

    ```bash
    [apc]
        driver = usbhid-ups
        port = auto
        desc = "APC UPS"
    ```

5. Configure NUT daemon

    ```bash
    sudo vi /etc/nut/nut.conf
    ```

    Set:

    ```bash
    MODE=standalone
    ```

6. Configure upsd

    ```bash
    sudo vi /etc/nut/upsd.conf
    ```

    Add:

    ```bash
    LISTEN 127.0.0.1 3493
    ```

7. Configure users

    ```bash
    sudo vi /etc/nut/upsd.users
    ```

    Add:

    ```bash
    [upsmon]
        password = mypassword
        upsmon master
    ```

8. Configure monitoring

    ```bash
    sudo vi /etc/nut/upsmon.conf
    ```

    Add:

    ```bash
    MONITOR apc@localhost 1 upsmon mypassword master
    SHUTDOWNCMD "/sbin/shutdown -h +0"
    NOTIFYCMD /usr/sbin/upssched
    POLLFREQ 5
    ```

9. Start NUT services

    ```bash
    sudo systemctl start nut-server
    sudo systemctl start nut-monitor
    sudo systemctl enable nut-server
    sudo systemctl enable nut-monitor
    ```

10. Check UPS status

    ```bash
    upsc apc@localhost
    ```

