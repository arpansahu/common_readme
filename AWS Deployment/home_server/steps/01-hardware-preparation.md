### Part 1: Hardware Preparation

#### Laptop Specific Setup

This section covers critical configurations to convert a laptop into a stable, server-grade system. These are production-tested settings that prevent SSH disconnections, black screens, and ACPI errors.

#### 1. Disable All Sleep and Suspend (Mandatory)

1. Mask all sleep targets

    ```bash
    sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target power-save.target
    ```

2. Verify masking

    ```bash
    systemctl status sleep.target
    ```

    Expected output: masked (dead)

#### 2. Configure Lid and Power Button Behavior

1. Edit logind configuration

    ```bash
    sudo nano /etc/systemd/logind.conf
    ```

2. Set exact configuration

    ```ini
    HandlePowerKey=reboot
    HandleSuspendKey=ignore
    HandleHibernateKey=ignore
    HandleLidSwitch=ignore
    HandleLidSwitchExternalPower=ignore
    HandleLidSwitchDocked=ignore
    PowerKeyIgnoreInhibited=no
    ```

    What this achieves:
    - Power button triggers clean reboot
    - Lid close is completely ignored
    - No accidental suspend
    - Fixes ACPI "no installed handler" error

3. Restart logind service

    ```bash
    sudo systemctl restart systemd-logind
    ```

    Warning: This may briefly disconnect SSH sessions.

4. Verify configuration

    ```bash
    loginctl show-logind | grep HandleLidSwitch
    ```

    Expected output:
    ```
    HandleLidSwitch=ignore
    HandleLidSwitchExternalPower=ignore
    HandleLidSwitchDocked=ignore
    ```

#### 3. Fix ACPI and Black Screen Issues

1. Force legacy sleep model

    ```bash
    sudo nano /etc/default/grub
    ```

2. Update GRUB command line

    Find the line starting with `GRUB_CMDLINE_LINUX_DEFAULT` and change to:

    ```ini
    GRUB_CMDLINE_LINUX_DEFAULT="quiet splash acpi=force button.lid_init_state=open mem_sleep_default=deep"
    ```

3. Apply GRUB changes

    ```bash
    sudo update-grub
    sudo reboot
    ```

4. Verify sleep mode

    ```bash
    cat /sys/power/mem_sleep
    ```

    Expected output: `[deep]`

#### 4. Fix Intel GPU Freeze (Black Screen Prevention)

1. Create Intel GPU configuration

    ```bash
    sudo tee /etc/modprobe.d/i915.conf <<EOF
    options i915 enable_dc=0 enable_fbc=0
    EOF
    ```

2. Reboot system

    ```bash
    sudo reboot
    ```

#### 5. Disable WiFi Power Saving

WiFi power saving causes SSH disconnections and network instability.

1. Create NetworkManager configuration

    ```bash
    sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf <<EOF
    [connection]
    wifi.powersave = 2
    EOF
    ```

2. Restart NetworkManager

    ```bash
    sudo systemctl restart NetworkManager
    ```

3. Disable at kernel level (extra safety)

    Find WiFi interface:

    ```bash
    iw dev
    ```

    Disable power saving (replace wlp2s0 with your interface):

    ```bash
    sudo iw dev wlp2s0 set power_save off
    ```

#### 6. Configure SSH Keep-Alive

1. Edit SSH daemon configuration

    ```bash
    sudo nano /etc/ssh/sshd_config
    ```

2. Add keep-alive settings

    ```ini
    ClientAliveInterval 30
    ClientAliveCountMax 3
    ```

3. Restart SSH service

    ```bash
    sudo systemctl restart ssh
    ```

#### 7. Enable Emergency Kernel Reboot

If system hangs, you can force reboot without power cycling.

1. Enable SysRq

    ```bash
    sudo tee /etc/sysctl.d/99-sysrq.conf <<EOF
    kernel.sysrq = 1
    EOF
    ```

2. Apply changes

    ```bash
    sudo sysctl -p
    ```

3. Emergency reboot shortcut

    If system freezes: `Alt + SysRq + B`

    This triggers immediate kernel reboot.

#### 8. Use Ethernet Connection

Important: Laptop WiFi is not 24/7 server-grade. Always use Ethernet for:
- Stable connectivity
- No power saving issues
- Predictable network behavior
- Better performance

#### 9. Verify Laptop Server Configuration

Run verification checklist:

```bash
# Check logind settings
loginctl show-logind | grep Handle

# Check sleep targets are masked
systemctl status sleep.target

# Check ACPI logs
journalctl -b | grep -i acpi

# Check WiFi power save
iw dev wlp2s0 get power_save

# Check SSH keep-alive
sudo sshd -T | grep ClientAlive
```

Expected results:
- All Handle* settings show "ignore" or "reboot"
- sleep.target shows "masked"
- No ACPI errors in logs
- WiFi power_save shows "off"
- SSH ClientAlive settings present

#### 10. Final Laptop Server Behavior

After completing these steps:

| Action | Result |
| ------ | ------ |
| Close lid | System keeps running |
| Press power button | Clean reboot |
| SSH idle for hours | Connection stays alive |
| Open lid | Screen wakes (optional) |
| System hang | Alt+SysRq+B forces reboot |

Important Notes:
- Keep laptop on well-ventilated surface
- Never run inside closed bag
- Monitor temperatures with `sensors` or `htop`
- External monitor recommended for setup only
- Lid should remain closed during operation

