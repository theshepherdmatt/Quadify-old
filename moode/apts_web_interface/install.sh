#!/bin/bash

start_time=$(date +"%T")
log_file="install_log.txt"
echo "Installation started at $start_time" > "$log_file"

echo "* Installing: Quadify ToolSet (web interface)" | tee -a "$log_file"

# Dynamically determine the user's home directory and username
if [ ! -z "$SUDO_USER" ]; then
    user_home=$(eval echo ~$SUDO_USER)
    user_name=$SUDO_USER
else
    user_home=$HOME
    user_name=$USER
fi

web_interface_dir="${user_home}/Quadify/moode/apts_web_interface"

# Proceed with the installation steps, ensuring paths and permissions are correctly set
# The steps would include installing Node.js, any necessary modules, and setting up the web interface

echo "Enabling Quadify ToolSet service..." | tee -a "$log_file"
service_file="/etc/systemd/system/apts_web_interface.service"

# Create the service file using the dynamically determined paths
cat > "$service_file" <<EOF
[Unit]
Description=Quadify toolset in a web interface
After=mpd.service
Requires=mpd.service

[Service]
WorkingDirectory=$web_interface_dir
ExecStart=/usr/bin/env node $web_interface_dir/apts_web_interface.js
Type=simple
Restart=always
User=$user_name

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the new service
if systemctl daemon-reload >> "$log_file" 2>&1 && \
   systemctl enable apts_web_interface >> "$log_file" 2>&1 && \
   systemctl start apts_web_interface >> "$log_file" 2>&1; then
    echo "Quadify ToolSet service enabled & started successfully" | tee -a "$log_file"
else
    echo "Failed to enable Quadify ToolSet service. Check log for details." | tee -a "$log_file"
fi

end_time=$(date +"%T")
echo "* End of installation: Quadify ToolSet (web interface) - no reboot required" | tee -a "$log_file"
echo "Installation started at $start_time and finished at $end_time" | tee -a "$log_file"
