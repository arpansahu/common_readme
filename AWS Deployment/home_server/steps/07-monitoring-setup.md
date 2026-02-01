### Part 8: Monitoring Setup

1. Install monitoring tools

    ```bash
    # System monitoring
    sudo apt install htop iotop nethogs

    # Disk monitoring
    sudo apt install smartmontools
    sudo systemctl enable smartd
    ```

2. Setup email alerts (using Mailjet)

    ```bash
    sudo apt install python3-pip
    pip3 install mailjet-rest
    ```

3. Create alert script

    ```bash
    sudo vi /usr/local/bin/system-alert.sh
    ```

    Add:

    ```bash
    #!/bin/bash

    # Check disk space
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

    if [ $DISK_USAGE -gt 80 ]; then
        python3 <<END
    from mailjet_rest import Client
    api_key = 'YOUR_API_KEY'
    api_secret = 'YOUR_API_SECRET'
    mailjet = Client(auth=(api_key, api_secret), version='v3.1')
    data = {
        'Messages': [{
            "From": {"Email": "alerts@yourdomain.com"},
            "To": [{"Email": "your@email.com"}],
            "Subject": "Home Server Alert: High Disk Usage",
            "TextPart": "Disk usage is at ${DISK_USAGE}%"
        }]
    }
    mailjet.send.create(data=data)
    END
    fi
    ```

4. Add monitoring to cron

    ```bash
    crontab -e
    ```

    Add:

    ```bash
    0 * * * * /usr/local/bin/system-alert.sh
    ```

