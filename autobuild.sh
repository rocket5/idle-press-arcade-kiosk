#!/bin/bash
set -ex

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

APP_PATH=$1
APP_NAME=$(basename "$APP_PATH")
echo "Setting up kiosk mode for application: ${APP_NAME}"
echo "Application path: ${APP_PATH}"

apt-get update && apt-get upgrade -y
# https://ubuntu.com/landscape/docs/install-landscape-client
apt-get install -y gnome-kiosk ydotool
snap install landscape-client
apt remove -y unattended-upgrades update-notifier

# Disable automatic updates
cat <<-EOF > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF

echo "enabled=0" > /etc/default/apport

# Configure GRUB for quick boot
cat <<-EOF > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=0
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""
GRUB_RECORDFAIL_TIMEOUT=0
GRUB_DISABLE_RECOVERY="true"
EOF

update-grub

function kiosk_mode {
  GDM_PATH="/etc/gdm3/custom.conf"
  DEFAULT_SESSION="gnome-kiosk-script-wayland"
  DEFAULT_SESSION_PATH="/var/lib/AccountsService/users/user"
  KIOSK_SCRIPT="/home/user/.local/bin/gnome-kiosk-script"
  KIOSK_SESSION="/usr/share/gnome-session/sessions/gnome-kiosk-script.session"
  WAYLAND_SESSION="/usr/share/wayland-sessions/gnome-kiosk-script-wayland.desktop"

  echo "Creating necessary directories..."
  # Ensure the user session directory exists
  mkdir -p /var/lib/AccountsService/users/
  mkdir -p /usr/share/gnome-session/sessions/
  mkdir -p /usr/share/wayland-sessions/
  
  echo "Setting up user session configuration..."
  # Create user session configuration
  cat <<-EOF > $DEFAULT_SESSION_PATH
[User]
Session=$DEFAULT_SESSION
Icon=/home/user/.face
SystemAccount=false

[InputSource0]
xkb=us
EOF

  echo "Configuring GDM for automatic login..."
  # Configure GDM for automatic login
  cat <<-EOF > $GDM_PATH
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=user
EOF

  echo "Setting up kiosk script..."
  # Create kiosk script directory and ensure it exists
  su - user -c "mkdir -p ~/.local/bin"
  
  # Create the kiosk script with proper content
  cat <<-EOF > $KIOSK_SCRIPT
#!/bin/bash
# Move mouse to corner to prevent interference
sudo ydotool mousemove 1920 1080

# Launch the application
$APP_PATH

# If the application exits, restart it after a short delay
sleep 1.0
exec "\$0" "\$@"
EOF

  # Set proper permissions for the kiosk script
  chown user:user $KIOSK_SCRIPT
  chmod 755 $KIOSK_SCRIPT

  echo "Creating GNOME session files..."
  # Create GNOME session file
  cat <<-EOF > $KIOSK_SESSION
[GNOME Session]
Name=Kiosk
RequiredComponents=org.gnome.Kiosk;org.gnome.Kiosk.Script;
EOF

  # Create Wayland session file
  cat <<-EOF > $WAYLAND_SESSION
[Desktop Entry]
Name=Kiosk Script Session (Wayland)
Comment=Logs you into the session started by ~/.local/bin/gnome-kiosk-script
Exec=gnome-session --session gnome-kiosk-script
TryExec=gnome-session
Type=Application
DesktopNames=GNOME-Kiosk;GNOME;
X-GDM-SessionRegisters=true
X-GDM-CanRunHeadless=true
EOF

  # Set proper permissions for session files
  chmod 644 $KIOSK_SESSION
  chmod 644 $WAYLAND_SESSION
}

echo "Setting up operator mode access..."
# Enable operator TTY at ctrl + alt + F3
cp "${SCRIPT_DIR}/kiosk-configuration/autologin@.service" /etc/systemd/system/
systemctl enable autologin@tty3.service
systemctl start autologin@tty3.service
echo "user  ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/user-nopassword

# Set up operator mode
su - user -c "mkdir -p ~/bin"
cp "${SCRIPT_DIR}/kiosk-configuration/operator-mode" /home/user/bin/
chmod +x /home/user/bin/operator-mode
chown user:user /home/user/bin/operator-mode

# Set up operator mode desktop shortcut
su - user -c "mkdir -p ~/Desktop"
cp "${SCRIPT_DIR}/kiosk-configuration/exit-operator-mode.desktop" /home/user/Desktop/
chmod +x /home/user/Desktop/exit-operator-mode.desktop
chown user:user /home/user/Desktop/exit-operator-mode.desktop

# Try to set trusted attribute, but don't fail if it doesn't work
echo "Setting desktop shortcut trust (this may show an error, which is OK)..."
su - user -c "gio set ~/Desktop/exit-operator-mode.desktop 'metadata::trusted' true" || true

echo "Configuring kiosk mode..."
# Write out all kiosk mode configuration 
kiosk_mode

echo "Setting up fail-safe mode..."
# Enable fail-safe game mode
cp "${SCRIPT_DIR}/kiosk-configuration/ensure-kiosk-mode.service" /etc/systemd/system/ensure-kiosk-mode.service
systemctl enable ensure-kiosk-mode.service

# Write out the fail-safe shell script
cat <<-EOF > /usr/local/bin/ensure-kiosk-mode.sh
#!/bin/bash
if [ -f "/usr/local/share/operator-mode" ]; then
    sed -i 's/gnome-kiosk-script-wayland/ubuntu/g' /var/lib/AccountsService/users/user
    rm /usr/local/share/operator-mode
else
    sed -i 's/ubuntu/gnome-kiosk-script-wayland/g' /var/lib/AccountsService/users/user
fi
EOF
chmod 755 /usr/local/bin/ensure-kiosk-mode.sh

echo "Applying user settings..."
# Apply user settings for operator mode
cp "${SCRIPT_DIR}/user-settings.sh" /home/user/
chmod +x /home/user/user-settings.sh
chown user:user /home/user/user-settings.sh

# Create a wrapper script to handle D-Bus/X11 display warnings
cat <<-EOF > /home/user/apply-settings.sh
#!/bin/bash
# Wait for display to be available
sleep 5
# Apply settings
bash /home/user/user-settings.sh
EOF
chmod +x /home/user/apply-settings.sh
chown user:user /home/user/apply-settings.sh

# Run the settings script directly (will show warnings but continue)
su - user -c "bash /home/user/user-settings.sh"

# Also schedule the settings to be applied after login
su - user -c "mkdir -p ~/.config/autostart"
cat <<-EOF > /home/user/.config/autostart/apply-settings.desktop
[Desktop Entry]
Type=Application
Name=Apply Kiosk Settings
Exec=/home/user/apply-settings.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
chown user:user /home/user/.config/autostart/apply-settings.desktop

echo "Verifying kiosk mode setup..."
echo "Checking critical files:"
echo "1. Kiosk script:"
ls -la /home/user/.local/bin/gnome-kiosk-script || echo "WARNING: Kiosk script not found!"
echo "2. GNOME session file:"
ls -la /usr/share/gnome-session/sessions/gnome-kiosk-script.session || echo "WARNING: GNOME session file not found!"
echo "3. Wayland session file:"
ls -la /usr/share/wayland-sessions/gnome-kiosk-script-wayland.desktop || echo "WARNING: Wayland session file not found!"
echo "4. User session configuration:"
ls -la /var/lib/AccountsService/users/user || echo "WARNING: User session configuration not found!"

echo "Checking session configuration content:"
echo "Current user session setting:"
cat /var/lib/AccountsService/users/user

echo "Kiosk mode setup complete. Reboot the system to enter kiosk mode."
