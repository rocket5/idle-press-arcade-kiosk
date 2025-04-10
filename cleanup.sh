#!/bin/bash
set -ex

echo "Removing kiosk mode components..."

# Stop and disable services
systemctl stop ensure-kiosk-mode.service || true
systemctl disable ensure-kiosk-mode.service || true
systemctl stop autologin@tty3.service || true
systemctl disable autologin@tty3.service || true

# Remove service files
rm -f /etc/systemd/system/ensure-kiosk-mode.service
rm -f /etc/systemd/system/autologin@.service

# Remove kiosk scripts and configurations
rm -f /usr/local/bin/ensure-kiosk-mode.sh
rm -f /home/user/.local/bin/gnome-kiosk-script
rm -f /usr/share/gnome-session/sessions/gnome-kiosk-script.session
rm -f /usr/share/wayland-sessions/gnome-kiosk-script-wayland.desktop
rm -f /home/user/Desktop/exit-operator-mode.desktop
rm -f /home/user/bin/operator-mode
rm -f /usr/local/share/operator-mode

# Remove user settings and autostart
rm -f /home/user/user-settings.sh
rm -f /home/user/apply-settings.sh
rm -f /home/user/.config/autostart/apply-settings.desktop

# Reset GDM configuration
cat <<-EOF > /etc/gdm3/custom.conf
[daemon]
AutomaticLoginEnable=false
AutomaticLogin=
EOF

# Reset user session
cat <<-EOF > /var/lib/AccountsService/users/user
[User]
Session=ubuntu
Icon=/home/user/.face
SystemAccount=false

[InputSource0]
xkb=us
EOF

# Remove sudo access
rm -f /etc/sudoers.d/user-nopassword

# Remove auto-update configuration
rm -f /etc/apt/apt.conf.d/20auto-upgrades

# Reset GRUB configuration
cat <<-EOF > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""
EOF

update-grub

echo "Cleanup complete. Please reboot the system." 