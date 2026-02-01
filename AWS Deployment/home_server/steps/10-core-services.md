### Part 11: Install Core Services

Now that your home server is configured, proceed with installing services:

1. [Docker Installation](docker_installation.md)
2. [Nginx Basic Setup](nginx.md)
3. [Nginx HTTPS Setup](nginx_https.md)
4. [Kubernetes with Portainer](kubernetes_with_portainer/deployment.md)
5. Other services as needed

### Common Issues and Fixes

1. Server not accessible from internet

    Cause: Port forwarding not working or ISP blocking ports

    Fix:

    - Verify port forwarding in router
    - Check if ISP blocks ports 80/443
    - Test with online port checker
    - Consider using Cloudflare Tunnel as alternative

2. Dynamic DNS not updating

    Cause: Update script failing or service down

    Fix:

    ```bash
    # Test update script manually
    /usr/local/bin/update-ddns.sh

    # Check cron logs
    grep CRON /var/log/syslog
    ```

3. UPS not detected

    Cause: Driver issues or USB connection

    Fix:

    ```bash
    # List USB devices
    lsusb

    # Check NUT logs
    sudo journalctl -u nut-server
    ```

4. Laptop overheating

    Cause: Poor ventilation or dust

    Fix:

    - Clean laptop vents
    - Use cooling pad
    - Monitor temperature:
      ```bash
      sudo apt install lm-sensors
      sensors
      ```

5. High disk usage

    Cause: Docker logs or old backups

    Fix:

    ```bash
    # Clean Docker logs
    docker system prune -a

    # Clean old backups
    find /backup -type f -mtime +30 -delete
    ```

### Performance Optimization

1. Disable unnecessary services

    ```bash
    sudo systemctl disable bluetooth
    sudo systemctl disable cups
    ```

2. Configure swap for low RAM

    ```bash
    sudo fallocate -l 4G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    ```

3. Enable automatic security updates

    ```bash
    sudo apt install unattended-upgrades
    sudo dpkg-reconfigure -plow unattended-upgrades
    ```

### Security Best Practices

1. Regular updates

    ```bash
    sudo apt update && sudo apt upgrade -y
    ```

2. Monitor logs

    ```bash
    sudo tail -f /var/log/auth.log
    ```

3. Check open ports

    ```bash
    sudo ss -tulnp
    ```

4. Review firewall rules

    ```bash
    sudo ufw status verbose
    ```

5. Check for unauthorized access

    ```bash
    sudo last
    sudo lastb
    ```

### Maintenance Checklist

**Daily:**
- Check system is accessible
- Verify services are running

**Weekly:**
- Review system logs
- Check disk space
- Test backups

**Monthly:**
- Update system packages
- Review firewall logs
- Clean Docker images
- Test UPS failover
- Verify backup restoration

**Quarterly:**
- Update all service configurations
- Review and update security policies
- Test disaster recovery procedures
- Clean hardware (dust removal)

### Final Verification Checklist

Run these commands to verify home server setup:

```bash
# Check static IP
ip addr show

# Check internet connectivity
ping -c 4 8.8.8.8

# Check DNS resolution
nslookup google.com

# Check firewall
sudo ufw status

# Check SSH service
sudo systemctl status sshd

# Check UPS status
upsc apc@localhost

# Check disk space
df -h

# Check memory
free -h

# Check running services
sudo systemctl list-units --type=service --state=running
```

### What This Setup Provides

After completing this guide, you will have:

1. Production-ready home server
2. Static local IP address
3. Dynamic DNS for domain access
4. Port forwarding configured
5. UPS power backup
6. Backup internet failover
7. Remote access via VPN
8. Automated monitoring and alerts
9. Automated backups
10. Security hardening
11. Maintenance automation

### Cost Breakdown

**One-time Costs:**
- Old laptop/desktop: $0-300 (repurpose existing)
- UPS: $80-150
- External HDD for backup: $50-80
- Total: $130-530

**Monthly Costs:**
- Electricity: ~$5-10 (depends on usage)
- Domain (optional): ~$1-2/month
- Backup mobile data: $0 (if included in plan)
- Total: ~$5-12/month

**Savings vs Cloud:**
- EC2 t2.small: ~$15/month
- Hostinger VPS: ~$10/month
- **Home Server: ~$7/month**
- **Annual Savings: $50-100**

