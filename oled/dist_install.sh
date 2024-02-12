#!/bin/bash

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define execution start time
start_time="$(date +"%T")"
echo -e "${BLUE}* Installing: Quadify OLED${NC}"
install_log="install_log.txt"
echo "" > "$install_log"

# Capture the invoking user's name and home directory
if [ "$SUDO_USER" ]; then
    real_user="$SUDO_USER"
    real_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    real_user="$USER"
    real_home="$HOME"
fi

# Update installation and logging directory
install_dir="$real_home/Quadify-FM3/moode/oled"
echo -e "${YELLOW}Creating installation directory at $install_dir...${NC}"
mkdir -p "$install_dir"
cd "$install_dir" || exit 1

# Update log file location
log_file="$install_dir/$install_log"

# Install Node.js if needed and dependencies
echo -e "${YELLOW}Installing Node.js environment and dependencies...${NC}" >> "$log_file"
apt-get update && apt-get install -y nodejs npm >> "$log_file" 2>&1
npm install pi-spi async onoff date-and-time socket.io-client i2c-bus >> "$log_file" 2>&1 || { echo -e "${RED}Failed to install Node.js dependencies. Check $log_file for details.${NC}"; exit 1; }

# Enable spi-dev module to allow hardware interfacing
echo -e "${YELLOW}Enabling SPI interface...${NC}" >> "$log_file"
if ! grep -q spi-dev "/etc/modules"; then
    echo "spi-dev" >> /etc/modules
fi
if ! grep -q dtparam=spi=on "/boot/config.txt"; then
    echo "dtparam=spi=on" >> /boot/config.txt
fi
if [ ! -f "/etc/modprobe.d/spidev.conf" ] || ! grep -q 'bufsiz=8192' "/etc/modprobe.d/spidev.conf"; then
    echo "options spidev bufsiz=8192" >> /etc/modprobe.d/spidev.conf
fi

# Register & enable service so display will run at boot
service_file="/etc/systemd/system/oled.service"
echo -e "${YELLOW}Creating and enabling Quadify OLED service...${NC}" >> "$log_file"
sudo bash -c "cat > $service_file" <<EOF
[Unit]
Description=Quadify OLED Display Service
After=mpd.service network.target
Wants=network.target
Requires=mpd.service

[Service]
WorkingDirectory=$install_dir
ExecStart=/bin/bash -c 'sleep 15; $install_dir/start_oled.sh'
ExecStop=/bin/node $install_dir/off.js
Restart=on-failure
StandardOutput=null
Type=simple
User=$real_user

[Install]
WantedBy=multi-user.target
EOF

# Path to the new launcher script
start_oled="$install_dir/start_oled.sh"

# Creating the launcher script with dynamic path
echo -e "${YELLOW}Creating start script for OLED display...${NC}"
echo "#!/bin/bash" > "$start_oled"
echo "/bin/node $install_dir/index.js moode" >> "$start_oled"

# Making the launcher script executable
chmod +x "$start_oled" || { echo -e "${RED}Failed to set executable permission for $start_oled${NC}"; exit 1; }
echo "Start script created at $start_oled" >> "$log_file"

systemctl daemon-reload >> "$log_file" 2>&1
systemctl enable oled >> "$log_file" 2>&1
echo -e "${GREEN}Quadify OLED service enabled (/etc/systemd/system/oled.service)${NC}" >> "$log_file"

# Attempt to start the service if SPI is available
if lsmod | grep -q "spidev" &> /dev/null; then
    systemctl start oled
    echo -e "${GREEN}Display should turn on. Quadify OLED installation complete (spidev module is already loaded, no reboot required)${NC}" >> "$log_file"
else
    echo -e "${YELLOW}Quadify OLED installation complete (spidev module is NOT loaded: a reboot is required)${NC}" >> "$log_file"
fi

# Final log entry
echo "Started at $start_time and finished at $(date +"%T")" >> "$log_file"
echo -e "${GREEN}Installation complete. Happy Listening $real_user!${NC}"
