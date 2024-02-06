#!/bin/bash

start_time=$(date +"%T")
starting_dir=${PWD}

echo "***   Installation of Quadify for moOde" 
echo "***   _____________________________________" 

# Install modules
for dir in "$starting_dir"/*; do
    if [ -d "$dir" ] && [ -f "$dir/install.sh" ]; then
        echo "Installing from $dir"
        (cd "$dir" && bash "./install.sh")
    fi
done

# Ensure return to the starting directory, though technically unnecessary due to subshell execution
cd "$starting_dir"

# ---------------------------------------------------
# Say something nice, show start time and end time
echo "* End of installation : Quadify for moOde"
echo "Started at $start_time and ended at $(date +"%T")"
