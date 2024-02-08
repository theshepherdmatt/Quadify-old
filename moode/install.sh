#!/bin/bash

start_time=$(date +"%T")
starting_dir=$(pwd) # Use $(pwd) for consistency with shell conventions
log_file="quadify_install_log.txt"

echo "*** Installation of Quadify for moOde ***"
echo "*****************************************"
echo "Installation log will be stored in $log_file"

# Check for root permissions
if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root. Exiting." | tee -a "$log_file"
    exit 1
fi

# Initialize log file
echo "Installation started at $start_time" > "$log_file"

module_found=false

# Install modules
for dir in "$starting_dir"/*; do
    if [ -d "$dir" ] && [ -f "$dir/install.sh" ]; then
        module_found=true
        echo "Installing from $dir" | tee -a "$log_file"
        if (cd "$dir" && bash "./install.sh" >> "$log_file" 2>&1); then
            echo "Successfully installed module from $dir" | tee -a "$log_file"
        else
            echo "Failed to install module from $dir. Check $log_file for details." | tee -a "$log_file"
        fi
    fi
done

if [ "$module_found" = false ]; then
    echo "No installable modules were found." | tee -a "$log_file"
fi

# Say something nice, show start time and end time
echo "* End of installation: Quadify for moOde" | tee -a "$log_file"
end_time=$(date +"%T")
echo "Started at $start_time and ended at $end_time" | tee -a "$log_file"
