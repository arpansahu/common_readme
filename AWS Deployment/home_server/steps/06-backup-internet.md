### Part 7: Backup Internet Connection

Configure automatic failover to mobile hotspot when primary internet fails.

1. Install usb-modeswitch (for USB modems)

    ```bash
    sudo apt install usb-modeswitch usb-modeswitch-data
    ```

2. Create connection check script

    ```bash
    sudo vi /usr/local/bin/check-internet.sh
    ```

    Add:

    ```bash
    #!/bin/bash

    # Primary connection check
    ping -c 3 8.8.8.8 > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "Primary connection down, switching to backup..."
        
        # Enable USB tethering or hotspot
        # This depends on your specific setup
        
        # Send alert
        curl -s -X POST "https://api.telegram.org/botYOUR_BOT_TOKEN/sendMessage" \
            -d "chat_id=YOUR_CHAT_ID" \
            -d "text=Home Server: Switched to backup internet"
    fi
    ```

    Make executable:

    ```bash
    sudo chmod +x /usr/local/bin/check-internet.sh
    ```

3. Add to cron

    ```bash
    crontab -e
    ```

    Add:

    ```bash
    */5 * * * * /usr/local/bin/check-internet.sh
    ```

