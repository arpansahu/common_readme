## 🐳 Docker Engine Installation (Updated for 2026)

**Reference:** [https://docs.docker.com/engine/install/ubuntu/](https://docs.docker.com/engine/install/ubuntu/)

**Current Server Versions:**
- Docker: 29.2.0 (February 2026)
- Docker Compose: v5.0.2 (plugin, not standalone)

---

### 1️⃣ Prerequisites & Repository Setup

#### 1.1 Update apt and install required packages

```bash
sudo apt-get update
sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release
```

---

#### 1.2 Add Docker's official GPG key (modern keyring approach)

```bash
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Important: avoid GPG permission issues
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

> 🔹 **Why this matters:**
> Earlier READMEs often skipped `chmod a+r`, which now causes GPG errors on newer Ubuntu versions.

---

#### 1.3 Add Docker repository

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

---

### 2️⃣ Install Docker Engine

#### 2.1 Update package index

```bash
sudo apt-get update
```

> If you still see GPG errors:

```bash
sudo chmod a+r /etc/apt/keyrings/docker.gpg
sudo apt-get update
```

---

#### 2.2 Install Docker Engine + Compose plugin

```bash
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-compose-plugin
```

✅ **Change vs old README:**

* `docker-compose-plugin` replaces old `docker-compose` binary
* Use `docker compose` (space) instead of `docker-compose` (hyphen)

---

### 3️⃣ Start & Enable Docker

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

---

### 4️⃣ Verify Installation

```bash
sudo docker run hello-world
```

✅ If you see **"Hello from Docker!"**, Docker is installed correctly.

**Verify versions:**

```bash
docker --version
# Expected: Docker version 29.x or later

docker compose version
# Expected: Docker Compose version v5.x or later
```

**Important:** Notice `docker compose` (with space), NOT `docker-compose` (with hyphen). The old `docker-compose` standalone binary is deprecated and not installed.

---

### 5️⃣ (Recommended) Run Docker Without sudo

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Verify:

```bash
docker ps
```

---

## ✅ Final Notes (Important Changes from Old Setup)

| Old Setup (Pre-2024)   | Current Setup (2026)            |
| ---------------------- | ------------------------------- |
| `docker-compose` (hyphen) | `docker compose` (space) - **plugin** |
| Docker v24.x           | Docker v29.2.0                  |
| Compose v2.23.x        | Compose v5.0.2                  |
| No key permission fix  | Explicit `chmod a+r docker.gpg` |
| Older install style    | Keyring-based (required now)    |
| Manual Compose install | Bundled via plugin              |

**Critical:** All docker-compose.yml files work with `docker compose` (space). Simply replace:
```bash
# Old way (deprecated):
docker-compose up -d

# New way (current):
docker compose up -d
```

---

## 📝 Common Docker Compose Commands

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Restart services
docker compose restart

# Pull latest images
docker compose pull

# Check status
docker compose ps
```

---

## 🔧 Troubleshooting

### "docker compose: command not found"

This means `docker-compose-plugin` is not installed. Install it:

```bash
sudo apt-get install docker-compose-plugin
```

### Old docker-compose.yml files not working

All old `docker-compose` files are compatible with `docker compose` (plugin). No changes needed to YAML files, just change the command.

---

## ✅ Next Steps

After Docker installation, you can install:
- [Portainer](../portainer/README.md) - Docker management UI
- [PostgreSQL](../postgres/README.md) - Database server
- [Redis](../redis/README.md) - Cache server
- [MinIO](../minio/README.md) - Object storage
- [Harbor](../harbor/README.md) - Container registry

See [INSTALLATION_ORDER.md](../INSTALLATION_ORDER.md) for recommended sequence.
