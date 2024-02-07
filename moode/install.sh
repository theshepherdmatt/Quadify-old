#!/bin/bash

# Define execution start time
start_time="$(date +"%T")"
log_file="install_log.txt"
echo "Installation initiated at $start_time" > "$log_file"

echo "* Installing: Quadify ToolSet (web interface)" | tee -a "$log_file"

# Capture the invoking user's name and home directory
if [ "$SUDO_USER" ]; then
    real_user="$SUDO_USER"
    real_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    real_user="$USER"
    real_home="$HOME"
fi

# Update installation and logging directory
install_dir="$real_home/Quadify/moode/apts_web_interface"
mkdir -p "$install_dir"

# Update log file location
log_file="$install_dir/$log_file"

echo "Installing Node.js..." | tee -a "$log_file"
if apt-get install -y nodejs >> "$log_file" 2>&1; then
    echo "Node.js installed successfully." | tee -a "$log_file"
else
    echo "Failed to install Node.js. Exiting..." | tee -a "$log_file"
    exit 1
fi

echo "Installing modules..." | tee -a "$log_file"
for file in "${install_dir}/ap_modules/*"; do 
    if [ -f "$file/install.sh" ]; then
        (cd "$file" && bash install.sh >> "$log_file" 2>&1)
        echo "Installed module from $file" | tee -a "$log_file"
    fi
done

echo "Enabling Quadify ToolSet service..." | tee -a "$log_file"
service_file="/etc/systemd/system/apts_web_interface.service"

cat > "$service_file" <<EOF
[Unit]
Description=Quadify toolset in a web interface
After=mpd.service
Requires=mpd.service

[Service]
WorkingDirectory=$install_dir
ExecStart=/usr/bin/env node $install_dir/apts_web_interface.js
Type=simple
Restart=always
User=$real_user

[Install]
WantedBy=multi-user.target
EOF

if systemctl daemon-reload >> "$log_file" 2>&1 && \
   systemctl enable apts_web_interface >> "$log_file" 2>&1 && \
   systemctl restart apts_web_interface >> "$log_file" 2>&1; then
    echo "Quadify ToolSet service enabled & started" | tee -a "$log_file"
else
    echo "Failed to enable Quadify ToolSet service. Check log for details." | tee -a "$log_file"
fi

end_time=$(date +"%T")
echo "* End of installation: Quadify ToolSet (web interface) - no reboot required" | tee -a "$log_file"
echo "Installation started at $start_time and finished at $end_time" | tee -a "$log_file"
exit 0
