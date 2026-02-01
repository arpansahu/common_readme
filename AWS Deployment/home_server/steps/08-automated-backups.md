### Part 9: Automated Backups

1. Create backup directory

    ```bash
    sudo mkdir -p /backup/docker-volumes
    sudo mkdir -p /backup/databases
    sudo mkdir -p /backup/configs
    ```

2. Create backup script

    ```bash
    sudo vi /usr/local/bin/backup-all.sh
    ```

    Add:

    ```bash
    #!/bin/bash

    DATE=$(date +%Y%m%d-%H%M%S)
    BACKUP_DIR="/backup"

    # Backup Docker volumes
    docker run --rm \
        -v /var/lib/docker/volumes:/source:ro \
        -v $BACKUP_DIR/docker-volumes:/backup \
        ubuntu tar czf /backup/volumes-$DATE.tar.gz -C /source .

    # Backup PostgreSQL
    docker exec postgres pg_dumpall -U postgres | gzip > $BACKUP_DIR/databases/postgres-$DATE.sql.gz

    # Backup configs
    tar czf $BACKUP_DIR/configs/etc-$DATE.tar.gz /etc/nginx /etc/default

    # Keep only last 7 days
    find $BACKUP_DIR -type f -mtime +7 -delete

    echo "Backup completed: $DATE"
    ```

    Make executable:

    ```bash
    sudo chmod +x /usr/local/bin/backup-all.sh
    ```

3. Schedule daily backups

    ```bash
    sudo crontab -e
    ```

    Add:

    ```bash
    0 2 * * * /usr/local/bin/backup-all.sh >> /var/log/backup.log 2>&1
    ```

