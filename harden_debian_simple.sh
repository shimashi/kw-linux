#!/bin/bash

# This script attempts to provide basic hardening for a Debian system.
#
# IMPORTANT CONSTRAINTS:
# - NO new packages will be installed. This means features like advanced password
#   complexity (e.g., libpam-pwquality), account lockout (e.g., pam_faillock),
#   firewall (e.g., UFW), and detailed auditing (e.g., auditd) are NOT included.
#   These features generally require package installations.
# - NO additional logging configuration beyond system defaults will be performed.
#
# IMPORTANT:
# - Run this script with root privileges.
# - ALWAYS test hardening scripts in a non-production environment first.
# - Review each section carefully and customize it for your specific needs.
# - Some changes may require a system reboot to take full effect.
# - This script is a starting point for basic hardening; for more robust
#   security, consider installing and configuring dedicated security tools.

# --- Configuration Variables (Customize as needed) ---
# Minimum password length (NOTE: Actual enforcement depends on PAM modules present)
MIN_PASS_LEN=7
# Password history (remember last N passwords)
PASS_HISTORY=0
# Days before password expires
PASS_MAX_DAYS=9999999999
# Days after password expires before account is locked
PASS_WARN_DAYS=7


# --- Helper Functions ---

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_message "ERROR: This script must be run as root."
        exit 1
    fi
}

# --- Hardening Functions ---

# 1. System Updates and Package Management (No new package installs)
update_system() {
    log_message "INFO: Starting system update and package management..."
    log_message "INFO: Updating package lists..."
    apt update -y

    log_message "INFO: Upgrading installed packages..."
    apt upgrade -y

    log_message "INFO: Performing distribution upgrade..."
    apt dist-upgrade -y

    log_message "INFO: Removing unused packages and dependencies..."
    apt autoremove -y
    apt clean

    log_message "INFO: System update and package management complete (no new packages installed per request)."
}

# 2. User and Authentication (No new PAM modules)
secure_users_auth() {
    log_message "INFO: Starting user and authentication hardening (limited by 'no new packages')..."

    log_message "INFO: Enforcing password aging policies globally in /etc/login.defs..."
    if [ -f /etc/login.defs ]; then
        sed -i '/^PASS_MAX_DAYS/c\PASS_MAX_DAYS	'$PASS_MAX_DAYS /etc/login.defs
        sed -i '/^PASS_MIN_DAYS/c\PASS_MIN_DAYS	1' /etc/login.defs # Allow password change after 1 day
        sed -i '/^PASS_WARN_AGE/c\PASS_WARN_AGE	'$PASS_WARN_DAYS /etc/login.defs
        log_message "INFO: /etc/login.defs updated for password aging."
    else
        log_message "WARN: /etc/login.defs not found. Skipping password aging configuration."
    fi

    log_message "INFO: Setting password history retention in /etc/pam.d/common-password..."
    # Add remember parameter to pam_unix.so in common-password
    # This relies on pam_unix.so and may not provide full password complexity without pam_pwquality.
    if [ -f /etc/pam.d/common-password ]; then
        if ! grep -q "pam_unix.so.*remember=" /etc/pam.d/common-password; then
            sed -i "s/\(pam_unix.so.*obscure\)/\1 remember=$PASS_HISTORY/" /etc/pam.d/common-password
            log_message "INFO: Password history set in /etc/pam.d/common-password. Consider 'minlen' in /etc/login.defs."
        else
            log_message "INFO: Password history already configured in /etc/pam.d/common-password. Review manually."
        fi
        # Attempt to set minlen via pam_unix.so if not already present
        if ! grep -q "pam_unix.so.*minlen=" /etc/pam.d/common-password; then
            sed -i "s/\(pam_unix.so.*obscure.*\)/\1 minlen=$MIN_PASS_LEN/" /etc/pam.d/common-password
            log_message "INFO: Attempted to set minlen for pam_unix.so in /etc/pam.d/common-password."
        fi
    else
        log_message "WARN: /etc/pam.d/common-password not found. Skipping password history configuration."
    fi


    log_message "INFO: Disabling root login via SSH (configure specific users for SSH access)..."
    if [ -f /etc/ssh/sshd_config ]; then
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak_simple_harden_$(date +%F)
        sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        log_message "INFO: PermitRootLogin set to no in /etc/ssh/sshd_config."
    else
        log_message "WARN: /etc/ssh/sshd_config not found. Skipping SSH root login configuration."
    fi

    log_message "INFO: Restricting 'su' command access to members of the 'sudo' group..."
    # This relies on common PAM configurations.
    # Debian's default /etc/pam.d/su usually only allows root to 'su' without password.
    # To restrict it further to a specific group (e.g., 'sudo' or 'wheel'),
    # 'pam_wheel.so' can be used, but it's not always enabled by default
    # and might be considered an "additional" module.
    # We will check if pam_wheel.so is already configured.
    if [ -f /etc/pam.d/su ]; then
        if grep -q "pam_wheel.so" /etc/pam.d/su; then
            log_message "INFO: pam_wheel.so detected in /etc/pam.d/su. Ensure it's configured for desired group (e.g., 'sudo')."
        else
            log_message "WARN: pam_wheel.so not configured in /etc/pam.d/su. 'su' restriction relies on default PAM behavior."
            log_message "WARN: For stronger 'su' restriction, consider adding 'auth required pam_wheel.so use_uid group=sudo' to /etc/pam.d/su (may require pam_wheel package)."
        fi
    else
        log_message "WARN: /etc/pam.d/su not found. Skipping su command restriction."
    fi

    log_message "INFO: User and authentication hardening complete (with limitations)."
}

# 3. Network Configuration (No UFW, minimal service disabling)
configure_network() {
    log_message "INFO: Starting network configuration hardening (no UFW, basic service review)..."

    log_message "WARN: No firewall (UFW) will be configured as no new packages are allowed. Ensure other network devices or cloud security groups provide firewalling."

    log_message "INFO: Hardening SSH configuration (/etc/ssh/sshd_config)..."
    if [ -f /etc/ssh/sshd_config ]; then
        if [ ! -f /etc/ssh/sshd_config.bak_simple_harden_$(date +%F) ]; then
            cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak_simple_harden_$(date +%F)
        fi

        sed -i 's/^#\?Protocol.*/Protocol 2/' /etc/ssh/sshd_config
        # sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config # Uncomment if using SSH keys only
        sed -i 's/^#\?GSSAPIAuthentication.*/GSSAPIAuthentication no/' /etc/ssh/sshd_config
        sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
        sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
        sed -i 's/^#\?ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
        sed -i 's/^#\?ClientAliveCountMax.*/ClientAliveCountMax 0/' /etc/ssh/sshd_config
        # Restrict ciphers and MACs (adjust based on modern recommendations)
        if ! grep -q "^Ciphers" /etc/ssh/sshd_config; then
            echo "Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com,aes256-ctr" >> /etc/ssh/sshd_config
        fi
        if ! grep -q "^MACs" /etc/ssh/sshd_config; then
            echo "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256" >> /etc/ssh/sshd_config
        fi
        log_message "INFO: SSH configuration updated. Restart SSH service to apply changes."
        systemctl restart sshd || service ssh restart
    else
        log_message "WARN: /etc/ssh/sshd_config not found. Skipping SSH hardening configuration."
    fi

    log_message "WARN: Manually review and disable unnecessary network services using 'systemctl disable <service>'. This script will not disable services by default."

    log_message "INFO: Network configuration hardening complete."
}

# 4. File System Hardening
harden_filesystem() {
    log_message "INFO: Starting file system hardening..."

    log_message "INFO: Restricting permissions on critical system files..."
    chmod 600 /etc/shadow      # Shadow file for password hashes
    chmod 644 /etc/passwd      # User account information
    chmod 644 /etc/etc/group       # Group information
    chmod 600 /boot/grub/grub.cfg # GRUB configuration
    chmod 600 /etc/sudoers # Sudoers file
    chmod 600 /etc/crontab # Crontab file
    chmod -R go-w /etc/cron.d /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly # Restrict cron directories

    log_message "INFO: Ensuring /tmp is mounted with noexec,nosuid,nodev..."
    if ! mount | grep -q " /tmp "; then
        log_message "WARN: /tmp is not a separate partition. Consider creating one for optimal security."
        log_message "INFO: Adding options to fstab for /tmp (tmpfs). Requires reboot to take effect if not remounted."
        if ! grep -q " /tmp .*noexec,nosuid,nodev" /etc/fstab; then
            echo "tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev 0 0" >> /etc/fstab
        fi
    fi
    mount -o remount,noexec,nosuid,nodev /tmp 2>/dev/null || log_message "WARN: Failed to remount /tmp with hardening options. Reboot required or manual intervention."

    log_message "INFO: Ensuring /var/tmp is mounted with noexec,nosuid,nodev (if separate mount point)..."
    if mount | grep -q " /var/tmp "; then
        mount -o remount,noexec,nosuid,nodev /var/tmp 2>/dev/null || log_message "WARN: Failed to remount /var/tmp. Reboot required or manual intervention."
    else
        log_message "INFO: /var/tmp is not a separate mount point. Consider managing its permissions manually."
        # If not separate, ensure it's not world writable
        chmod 1777 /var/tmp || log_message "WARN: Failed to set permissions for /var/tmp."
    fi

    log_message "INFO: Ensuring /dev/shm is mounted with noexec,nosuid,nodev..."
    if mount | grep -q " /dev/shm "; then
        mount -o remount,noexec,nosuid,nodev /dev/shm 2>/dev/null || log_message "WARN: Failed to remount /dev/shm. Reboot required or manual intervention."
    else
        log_message "WARN: /dev/shm not found or not mounted as tmpfs. Review system configuration."
    fi

    log_message "INFO: File system hardening complete."
}

# 5. Kernel Parameter Hardening (sysctl)
apply_sysctl_hardening() {
    log_message "INFO: Starting kernel parameter hardening (sysctl)..."

    log_message "INFO: Applying recommended sysctl settings..."
    cp /etc/sysctl.conf /etc/sysctl.conf.bak_simple_harden_$(date +%F)

    cat <<EOF >> /etc/sysctl.d/99-simple-harden.conf
# --- General IP Network Hardening ---
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.default.arp_ignore = 1
net.ipv4.conf.default.arp_announce = 2

# --- IPv6 Hardening (if not used, consider disabling completely) ---
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.autoconf = 0
net.ipv6.conf.default.autoconf = 0

# --- Kernel Hardening ---
kernel.exec-shield = 1
kernel.randomize_va_space = 2
kernel.dmesg_restrict = 1
kernel.unprivileged_userns_clone = 1

# --- File System Hardening ---
fs.suid_dumpable = 0
EOF

    sysctl -p /etc/sysctl.d/99-simple-harden.conf || log_message "WARN: Failed to apply sysctl settings. Check /etc/sysctl.d/99-simple-harden.conf for errors."

    log_message "INFO: Kernel parameter hardening complete. Some changes may require reboot."
}

# --- Main Execution ---
main() {
    check_root
    log_message "INFO: Starting Simple Debian Hardening Script (no new packages, no additional logging)."

    update_system
    secure_users_auth
    configure_network
    harden_filesystem
    # setup_logging_auditing function is intentionally omitted as per request.
    apply_sysctl_hardening

    log_message "INFO: Simple Debian Hardening Script finished."
    log_message "IMPORTANT: Review logs and reboot if necessary for all changes to take effect."
    log_message "IMPORTANT: This script provides basic hardening. For more comprehensive security, consider installing dedicated tools (e.g., UFW, auditd, libpam-pwquality)."
}

main "$@"
