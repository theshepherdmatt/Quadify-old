#!/bin/bash

# Define execution start time
start_time="$(date +"%T")"
echo "* Installing: Quadify OLED"
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
install_dir="$real_home/Quadify/moode/oled"
mkdir -p "$install_dir"
cd "$install_dir" || exit 1

# Update log file location
log_file="$install_dir/$install_log"

# ---------------------------------------------------
# Install Node.js if needed and dependencies
echo "Installing Node.js environment and dependencies..." >> "$log_file"
apt-get install -y nodejs npm >> "$log_file" 2>&1
npm install pi-spi async onoff date-and-time socket.io-client i2c-bus >> "$log_file" 2>&1 || { echo "Failed to install Node.js dependencies. Check $log_file for details."; exit 1; }

# ---------------------------------------------------
# Enable spi-dev module to allow hardware interfacing
echo "Enabling SPI interface..." >> "$log_file"
if ! grep -q spi-dev "/etc/modules"; then
    echo "spi-dev" >> /etc/modules
fi
if ! grep -q dtparam=spi=on "/boot/config.txt"; then
    echo "dtparam=spi=on" >> /boot/config.txt
fi
if [ ! -f "/etc/modprobe.d/spidev.conf" ] || ! grep -q 'bufsiz=8192' "/etc/modprobe.d/spidev.conf"; then
    echo "options spidev bufsiz=8192" >> /etc/modprobe.d/spidev.conf
fi

# ---------------------------------------------------
# Register & enable service so display will run at boot
service_file="/etc/systemd/system/oled.service"
echo "Creating and enabling Quadify OLED service..." >> "$log_file"
sudo bash -c "cat > $service_file" <<EOF
[Unit]
Description=Quadify OLED Display Service
After=mpd.service network.target
Wants=network.target
Requires=mpd.service

[Service]
WorkingDirectory=$install_dir
ExecStart=/bin/bash -c '$install_dir/start-oled.sh'
ExecStop=/bin/node $install_dir/off.js
StandardOutput=null
Type=idle
User=$real_user

[Install]
WantedBy=multi-user.target
EOF

# Ensure start-oled.sh is executable
chmod +x "$install_dir/start-oled.sh" >> "$log_file" 2>&1 || { echo "Failed to set executable permission for start-oled.sh"; exit 1; }

systemctl daemon-reload >> "$log_file" 2>&1
systemctl enable oled >> "$log_file" 2>&1
echo "Quadify OLED service enabled (/etc/systemd/system/oled.service)" >> "$log_file"

# Attempt to start the service if SPI is available
if lsmod | grep "spidev" &> /dev/null; then
    systemctl start oled
    echo "Display should turn on." >> "$log_file"
    echo "*End of installation: Quadify OLED (spidev module is already loaded, no reboot required)" >> "$log_file"
else
    echo "*End of installation: Quadify OLED (spidev module is NOT loaded: a reboot is required)" >> "$log_file"
fi

# Final log entry
echo "Started at $start_time and finished at $(date +"%T")" >> "$log_file"
