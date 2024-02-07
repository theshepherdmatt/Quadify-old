#!/bin/bash
/bin/node /home/matt/Quadify/moode/oled/index.js moode &
# Wait for index.js to fully start. Adjust the sleep time as needed.
sleep 5
/bin/node /home/matt/Quadify/moode/oled/buttonsleds.js
