#!/bin/sh

# 'td -d \n' removes \n characters
# Make sure you open LocalIP in VS Code to see this effect because Xcode automatically inserts new line when you open a file
# Have tried echo -n and xargs, did not work

echo "Get local IP and write to LocalIP"
ipconfig getifaddr en0 | tr -d '\n' > ./Subsystems/Sources/Backend/LocalIP
