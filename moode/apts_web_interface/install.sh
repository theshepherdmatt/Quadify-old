#!/bin/bash

start_time=$(date +"%T")
log_file="install_log.txt"
echo "Installation started at $start_time" > "$log_file"

echo "* Installing: Quadify ToolSet (web interface)" | tee -a "$log_file"
# Use the HOME environment variable to get the user's home directory
user_home=${HOME}
# Use the SUDO_USER or USER environment variables to get the effective username
user_name=${SUDO_USER:-${USER}}
start_pwd=$(pwd)

# Define the path to the web interface directory based on the user's home directory
web_interface_dir="${user_home}/Quadify/moode/apts_web_interface"

echo "Installing Node.js..." | tee -a "$log_file"
if apt-get install -y nodejs >> "$log_file" 2>&1; then
    echo "Node.js installed successfully." | tee -a "$log_file"
else
    echo "Failed to install Node.js. Exiting..." | tee -a "$log_file"
    exit 1
fi

echo "Installing modules..." | tee -a "$log_file"
for file in "${web_interface_dir}/ap_modules/*"; do 
    if [ -f "$file/install.sh" ]; then
        (cd "$file" && bash install.sh >> "$start_pwd/$log_file" 2>&1)
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
WorkingDirectory=$web_interface_dir
ExecStart=/usr/bin/env node $web_interface_dir/apts_web_interface.js
Type=simple
Restart=always
User=$user_name

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
