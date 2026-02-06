#!/bin/bash
set -e

echo "[$(date)] Starting certificate deployment"

# 1. Copy to nginx
sudo mkdir -p /etc/nginx/ssl/arpansahu.space
sudo cp ~/.acme.sh/arpansahu.space_ecc/fullchain.cer /etc/nginx/ssl/arpansahu.space/fullchain.pem
sudo cp ~/.acme.sh/arpansahu.space_ecc/arpansahu.space.key /etc/nginx/ssl/arpansahu.space/privkey.pem
sudo chown arpansahu:arpansahu /etc/nginx/ssl/arpansahu.space/*.pem
sudo chmod 644 /etc/nginx/ssl/arpansahu.space/fullchain.pem
sudo chmod 600 /etc/nginx/ssl/arpansahu.space/privkey.pem
echo "✅ Certificates copied to nginx"

# 2. Reload nginx
sudo systemctl reload nginx
echo "✅ Nginx reloaded"

# 3. Regenerate Kafka SSL keystores if kafka-deployment exists
if [ -d ~/kafka-deployment ]; then
    echo "Regenerating Kafka SSL keystores..."
    cd ~/kafka-deployment
    
    if [ -f ./generate_ssl_from_nginx.sh ]; then
        ./generate_ssl_from_nginx.sh
        echo "✅ Kafka keystores regenerated"
        
        # Restart Kafka to use new certificates
        docker compose -f docker-compose-kafka.yml restart
        echo "✅ Kafka restarted with new certificates"
    fi
fi

# 4. Update K3s certificates and upload to MinIO
if command -v kubectl &> /dev/null && [ -d ~/k3s_scripts ]; then
    echo "Updating K3s SSL certificates..."
    cd ~/k3s_scripts
    
    # Renew K3s keystores and secrets
    if [ -f ./1_renew_k3s_ssl_keystores.sh ]; then
        ./1_renew_k3s_ssl_keystores.sh
        echo "✅ K3s certificates updated"
    fi
    
    # Upload to MinIO for Django projects
    if [ -f ./2_upload_keystores_to_minio.sh ]; then
        ./2_upload_keystores_to_minio.sh
        echo "✅ Keystores uploaded to MinIO"
    fi
fi

echo "[$(date)] Certificate deployment completed"
