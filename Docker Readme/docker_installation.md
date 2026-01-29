## 🐳 Docker Engine Installation (Updated & Final)

**Reference:** [https://docs.docker.com/engine/install/ubuntu/](https://docs.docker.com/engine/install/ubuntu/)

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

## ✅ Final Notes (Important Differences from Old README)

| Old README             | Updated Approach                |
| ---------------------- | ------------------------------- |
| Used `docker-compose`  | Uses `docker compose` plugin    |
| No key permission fix  | Explicit `chmod a+r docker.gpg` |
| Older install style    | Keyring-based (required now)    |
| Manual Compose install | Bundled via plugin              |

---

### �� Next Step

Now this Docker setup is **Redis Commander–ready**.
Say **"next: redis commander"** and I'll give you the **final production setup** (port + optional Nginx + SSL).
