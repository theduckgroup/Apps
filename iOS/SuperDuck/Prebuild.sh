#!/bin/sh

# 'td -d \n' removes \n characters
# Make sure you open LocalIP in VS Code to see this effect because Xcode automatically inserts new line when you open a file
# Have tried echo -n and xargs, did not work

echo "Obtaining local IP address"
ipconfig getifaddr en0 | tr -d '\n' > ./Tmp/LocalIP
