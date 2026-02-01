# SSH Key Setup for Ubuntu Server Installation

## Overview

When installing Ubuntu Server, you'll be prompted to import SSH keys. This allows you to connect to your server without typing a password every time. This guide shows you how to generate SSH keys on your laptop and import them during server installation.

---

## Why SSH Keys?

✅ **Secure:** More secure than password authentication  
✅ **Convenient:** No need to type password for every login  
✅ **Required:** Needed for GitHub, automated deployments, etc.

---

## Part 1: Generate SSH Key on Your Laptop

**⚠️ IMPORTANT:** Do this on your **Mac or Windows laptop**, NOT on the server screen!

### For Mac (Terminal)

1. **Open Terminal app** (Cmd+Space, type "Terminal")

2. **Check if you already have a key:**
   ```bash
   ls -la ~/.ssh/id_ed25519.pub
   ```
   
   - If the file exists, **skip to Step 3**
   - If you see "No such file", continue to generate a new key

3. **Generate a new SSH key:**
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```
   
   **About the email (`-C` flag):**
   - This is just a **label/comment** to help you identify the key
   - It appears at the end of your public key file
   - Use your **actual email** (e.g., `arpansahu@gmail.com`) or any identifier
   - It's **NOT** used for authentication - just for your reference
   - Example: `ssh-ed25519 AAAAC3Nz... arpansahu@gmail.com`
   
   When prompted:
   - `Enter file in which to save the key`: Press **Enter** (accept default)
   - `Enter passphrase`: Press **Enter** (no passphrase) or type a secure passphrase
   - `Enter same passphrase again`: Press **Enter** or repeat passphrase

4. **Copy your public key to clipboard:**
   ```bash
   pbcopy < ~/.ssh/id_ed25519.pub
   ```
   
   ✅ Your SSH public key is now in your clipboard!

5. **Verify it was copied (optional):**
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   
   You should see something like:
   ```
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGx... your_email@example.com
   ```
   
   **Note:** The email at the end is just your label - it helps you remember "this is my laptop's key" when you have multiple keys.

---

### For Windows (PowerShell)

1. **Open PowerShell** (Windows key, type "PowerShell")

2. **Check if you already have a key:**
   ```powershell
   Test-Path ~/.ssh/id_ed25519.pub
   ```
   
   - If it returns `True`, **skip to Step 3**
   - If it returns `False`, continue to generate a new key

3. **Generate a new SSH key:**
   ```powershell
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```
   
   **About the email (`-C` flag):**
   - This is just a **label/comment** to help you identify the key
   - Use your **actual email** (e.g., `arpansahu@gmail.com`) or any identifier
   - It's **NOT** used for authentication - just for your reference
   - It appears at the end of your public key as a comment
   
   When prompted:
   - `Enter file in which to save the key`: Press **Enter** (accept default)
   - `Enter passphrase`: Press **Enter** (no passphrase) or type a secure passphrase
   - `Enter same passphrase again`: Press **Enter** or repeat passphrase

4. **Display your public key:**
   ```powershell
   cat ~/.ssh/id_ed25519.pub
   ```

5. **Copy the output:**
   - Highlight the entire line (starts with `ssh-ed25519` and ends with your email)
   - Right-click to copy

---

## Part 2: Upload SSH Key to GitHub

1. **Go to GitHub:**
   - Open browser and navigate to https://github.com
   - Log in to your account (username: `arpansahu`)

2. **Navigate to SSH Keys Settings:**
   - Click your **profile photo** in the top-right corner
   - Select **Settings**
   - In the left sidebar, click **SSH and GPG keys**

3. **Add New SSH Key:**
   - Click the green **New SSH key** button
   
   **Title:** Give it a descriptive name (e.g., "MacBook Pro", "Windows Laptop", "Work Computer")
   
   **Key type:** Leave as "Authentication Key"
   
   **Key:** Paste the key you copied earlier (should start with `ssh-ed25519`)

4. **Save:**
   - Click **Add SSH key**
   - GitHub may ask for your password to confirm

5. **Verify:**
   - You should now see your new key in the list
   - It will show when it was added and never used (until you use it)

---

## Part 3: Import SSH Key During Ubuntu Server Installation

Now go back to your Ubuntu Server installation screen.

### During Installation Process

When you reach the SSH setup screen that says:

```
You can choose to install the OpenSSH server package to enable
secure remote access to your server.
```

1. **Select:** `[ Install OpenSSH server ]` (press Space to select, should show `[X]`)

2. **Move down to:** `[ Import SSH Identity ]`

3. **Select it** (press Enter)

4. **Choose import method:** Select `[ from GitHub ]`

5. **Enter your GitHub username:** `arpansahu`

6. **Wait for import:**
   - The installer will connect to GitHub
   - It will download your public keys
   - You'll see a confirmation message

7. **Continue installation**

---

## Part 4: Test SSH Connection After Installation

After Ubuntu Server installation is complete and the server has booted:

### Get Server IP Address

On the server console, log in and run:
```bash
ip a
```

Look for your server's IP address (likely 192.168.1.XXX)

### Connect from Your Laptop

**From Mac Terminal or Windows PowerShell:**

```bash
ssh arpansahu@192.168.1.XXX
```

Replace `XXX` with your actual server IP.

**What should happen:**
- ✅ You should connect **without being asked for a password**
- ✅ You'll see the Ubuntu welcome message
- ✅ You're logged in as `arpansahu`

**If you set a passphrase:**
- You'll be asked for the **SSH key passphrase** (not server password)
- This is more secure than no passphrase

---

## Troubleshooting

### "Permission denied (publickey)"

**Cause:** Your SSH key wasn't imported correctly or GitHub username was wrong.

**Fix:**
1. On the server, check if the key was imported:
   ```bash
   cat ~/.ssh/authorized_keys
   ```
   
2. If empty or wrong, manually add your key:
   ```bash
   nano ~/.ssh/authorized_keys
   ```
   
   Paste your public key (from `pbcopy` or `cat ~/.ssh/id_ed25519.pub` on your laptop)
   
   Save with Ctrl+O, Enter, Ctrl+X

3. Set correct permissions:
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```

4. Try connecting again

---

### "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!"

**Cause:** You reinstalled the server, and SSH detects a different server at the same IP.

**Fix:**
```bash
ssh-keygen -R 192.168.1.XXX
```

Replace `XXX` with your server IP. Then try connecting again.

---

### Cannot Generate SSH Key (Mac)

**If you get "command not found: ssh-keygen":**
```bash
xcode-select --install
```

This installs command-line tools including SSH.

---

### Cannot Generate SSH Key (Windows)

**If you get "ssh-keygen is not recognized":**

1. Open PowerShell as Administrator
2. Run:
   ```powershell
   Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
   ```
3. Close and reopen PowerShell
4. Try again

---

## Security Best Practices

### Use a Passphrase

**Recommended:** Set a passphrase when generating your SSH key.

**Why?**
- If someone steals your laptop, they can't use your SSH key without the passphrase
- It's an extra layer of security

**How?**
- When `ssh-keygen` asks for a passphrase, type a secure password
- You'll need to enter it once when you first SSH (then your OS remembers it for the session)

### Multiple Keys for Multiple Servers

If you manage many servers, you can create separate keys:

```bash
# For production server
ssh-keygen -t ed25519 -C "prod-server" -f ~/.ssh/id_ed25519_prod

# For development server
ssh-keygen -t ed25519 -C "dev-server" -f ~/.ssh/id_ed25519_dev
```

Then create `~/.ssh/config`:
```
Host prod
    HostName 122.176.93.72
    User arpansahu
    IdentityFile ~/.ssh/id_ed25519_prod

Host dev
    HostName 192.168.1.200
    User arpansahu
    IdentityFile ~/.ssh/id_ed25519_dev
```

Now you can connect with:
```bash
ssh prod
ssh dev
```

---

## Summary Checklist

**Before Server Installation:**
- [ ] Generate SSH key on your laptop
- [ ] Upload public key to GitHub
- [ ] Verify key appears in GitHub Settings → SSH keys

**During Server Installation:**
- [ ] Select "Install OpenSSH server"
- [ ] Select "Import SSH Identity"
- [ ] Choose "from GitHub"
- [ ] Enter username: `arpansahu`
- [ ] Confirm import successful

**After Server Installation:**
- [ ] Get server IP address: `ip a`
- [ ] Test connection: `ssh arpansahu@SERVER_IP`
- [ ] Verify passwordless login works

---

## Quick Reference

### View Your Public Key
```bash
# Mac/Linux
cat ~/.ssh/id_ed25519.pub

# Windows PowerShell
cat ~/.ssh/id_ed25519.pub
```

### Copy Public Key to Clipboard
```bash
# Mac
pbcopy < ~/.ssh/id_ed25519.pub

# Linux (with xclip)
xclip -sel clip < ~/.ssh/id_ed25519.pub

# Windows PowerShell
cat ~/.ssh/id_ed25519.pub | clip
```

### Test SSH Connection
```bash
ssh arpansahu@192.168.1.200    # LAN
ssh arpansahu@122.176.93.72    # Public IP
ssh arpansahu@arpansahu.space  # Domain
```

### GitHub SSH Keys URL
https://github.com/settings/keys

---

## Next Steps

After SSH is working:

1. Continue with server installation
2. Follow **[FRESH_INSTALLATION_GUIDE.md](../FRESH_INSTALLATION_GUIDE.md)** from Phase 1
3. All subsequent SSH connections will be passwordless! 🎉

---

**Your SSH key is now set up! You can connect securely to your server! 🔐**
