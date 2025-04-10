# indie-darling-arcade

## Arcade Kiosk Mode Setup
This package provides a complete kiosk mode setup for running games or applications in a controlled, automated environment on Ubuntu 24.04 LTS. It includes both kiosk mode for running your application and operator mode for maintenance.

## Prerequisites

- Ubuntu 24.04 LTS
- A user account named "user" (the script is configured for this username)
- Your application/game executable
- Root/sudo access for initial setup

## Package Contents

- `autobuild.sh` - Main setup script
- `cleanup.sh` - Script to remove previous kiosk installation
- `kiosk-configuration/` - Configuration files for kiosk and operator modes
  - `autologin@.service` - Operator mode login service
  - `ensure-kiosk-mode.service` - Fail-safe kiosk mode service
  - `operator-mode` - Operator mode control script
  - `exit-operator-mode.desktop` - Desktop shortcut for exiting operator mode
- `user-settings.sh` - Visual settings for operator mode

## Installation Steps

1. **Clean Previous Installation (if any)**
   ```bash
   # Make the cleanup script executable
   chmod +x cleanup.sh
   
   # Run the cleanup script
   sudo ./cleanup.sh
   
   # Reboot the system
   sudo reboot
   ```

2. **Prepare Your Application**
   ```bash
   # Create the game directory
   mkdir -p /home/user/arcade
   
   # Copy your game executable to the directory
   # Replace 'your-game' with your actual game executable
   cp /path/to/your/game /home/user/arcade/arcade.x86_64
   
   # Set proper permissions
   chmod +x /home/user/arcade/arcade.x86_64
   sudo chown -R user:user /home/user/arcade
   ```

3. **Set Up Kiosk Mode**
   ```bash
   # Make the setup script executable
   chmod +x autobuild.sh
   
   # Run the setup script with your game's path
   sudo ./autobuild.sh /home/user/arcade/arcade.x86_64
   ```

4. **Reboot the System**
   ```bash
   sudo reboot
   ```

## Features

### Kiosk Mode
- Automatic boot into your application
- Disabled system updates and notifications
- Mouse cursor moved to corner to prevent interference
- Auto-restart if the application crashes
- Hidden boot menu for quick startup

### Operator Mode
- Access via Ctrl+Alt+F3
- Clean, professional desktop environment
- Desktop shortcut to exit operator mode
- Full system access for maintenance
- Automatic return to kiosk mode after maintenance

## Usage

### Normal Operation
- System boots directly into your application
- No user intervention required
- Application runs in full-screen mode

### Entering Operator Mode
1. Press Ctrl+Alt+F3
2. System will switch to operator desktop
3. Perform necessary maintenance
4. Use the "Exit Operator Mode" desktop shortcut to return to kiosk mode

### Exiting Operator Mode
- Double-click the "Exit Operator Mode" shortcut on the desktop
- System will reboot and return to kiosk mode

## Maintenance

### Updating Your Application
1. Enter operator mode (Ctrl+Alt+F3)
2. Replace the game executable in `/home/user/arcade/`
3. Ensure proper permissions:
   ```bash
   chmod +x /home/user/arcade/arcade.x86_64
   sudo chown user:user /home/user/arcade/arcade.x86_64
   ```
4. Exit operator mode to return to kiosk mode

### System Updates
- System updates are disabled by default
- To perform system updates:
  1. Enter operator mode
  2. Run system updates manually
  3. Exit operator mode to return to kiosk mode

## Troubleshooting

### Application Not Starting
1. Enter operator mode (Ctrl+Alt+F3)
2. Check application permissions:
   ```bash
   ls -l /home/user/arcade/arcade.x86_64
   ```
3. Verify the application runs manually:
   ```bash
   /home/user/arcade/arcade.x86_64
   ```
4. Check system logs:
   ```bash
   journalctl -xe
   ```

### Operator Mode Not Working
1. Verify the operator mode service:
   ```bash
   systemctl status autologin@tty3.service
   ```
2. Check operator mode script permissions:
   ```bash
   ls -l /home/user/bin/operator-mode
   ```
3. Verify desktop shortcut:
   ```bash
   ls -l /home/user/Desktop/exit-operator-mode.desktop
   ```

### Clean Installation
If you need to start fresh:
1. Run the cleanup script:
   ```bash
   sudo ./cleanup.sh
   ```
2. Reboot the system
3. Follow the installation steps from the beginning

## Security Notes

- The system is configured for a single-purpose kiosk
- Operator mode provides full system access
- Consider physical security measures for the operator mode access
- The user account has sudo access without password for maintenance

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review system logs
3. Verify all file permissions and ownership
4. Ensure the user account is named "user"

## License

This package is provided as-is with no warranty. Use at your own risk.
