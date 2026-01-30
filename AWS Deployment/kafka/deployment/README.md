# Kafka + AKHQ Deployment Files

This directory contains all the necessary files to deploy Apache Kafka with AKHQ web UI.

## Files Overview

### Configuration Files

- **`.env`** - Environment variables for Kafka and AKHQ (keep this secure!)
- **`.env.example`** - Template for creating your own `.env` file

### Docker Compose Files

- **`docker-compose-kafka.yml`** - Kafka broker with KRaft mode, SASL/SSL authentication
- **`docker-compose-akhq.yml`** - AKHQ web UI with form-based authentication

### Scripts

- **`generate_ssl_from_nginx.sh`** - Converts nginx SSL certificates to Java keystores for Kafka

### Generated Files (created by scripts)

- **`ssl/`** directory (created by `generate_ssl_from_nginx.sh`)
  - `kafka.keystore.jks` - Kafka SSL keystore
  - `kafka.truststore.jks` - Kafka SSL truststore
  - `kafka.p12` - Intermediate PKCS12 file
  - `*_creds` files - Password credential files

## Quick Start

1. **Copy `.env.example` to `.env` and update with your passwords:**
   ```sh
   cp .env.example .env
   nano .env  # Edit with your secure passwords
   ```

2. **Generate SSL keystores from nginx certificates:**
   ```sh
   ./generate_ssl_from_nginx.sh
   ```

3. **Create Docker network:**
   ```sh
   docker network create kafka-network
   ```

4. **Start Kafka:**
   ```sh
   docker compose -f docker-compose-kafka.yml up -d
   ```

5. **Start AKHQ:**
   ```sh
   docker compose -f docker-compose-akhq.yml up -d
   ```

6. **Access AKHQ at:** https://kafka.arpansahu.space/ui

## Documentation

For detailed setup and configuration instructions, see:

- **[Kafka.md](../Kafka.md)** - Complete Kafka setup guide
- **[AKHQ.md](../AKHQ.md)** - Complete AKHQ setup guide

## Security Notes

⚠️ **IMPORTANT:**

1. **Never commit `.env` file** - Contains sensitive passwords
2. **Change all default passwords** in `.env` file
3. **BCrypt hashes** for AKHQ must be generated for your passwords
4. **SSL passwords must match** - All three SSL passwords must be identical

## Support

For issues or questions, refer to the documentation files or check logs:

```sh
docker logs kafka-kraft
docker logs akhq
```
