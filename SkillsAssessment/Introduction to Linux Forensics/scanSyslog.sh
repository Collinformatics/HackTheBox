#!/bin/bash

# Scan sysmon log for events
# To run the command pipe read the log file and pipe it to this script.
# Ex:
	# cat /var/log/syslog | sudo /opt/sysmon/sysmonLogView | bash scanSyslog.sh <search text>


# Inputs
log="/dev/stdin" # Pipe the log to this script 
search="$1" # Search text
sfile="syslogEvents.txt" # Saved scan

# Parameters
color='\e[91m'
colorB='\e[34m'
rst='\e[0m'


# Search doc
if [[ -z "$search" ]]; then
	echo "Usage: $0 <search text>"
	exit 1
fi
echo -e "Select events with: $colorB$search$rst"

# Buffer to store each block
buffer=""

# Read the file line by line
bar=$(printf '%*s' 50 '' | tr ' ' '*')
while IFS= read -r line; do
	# Start of a new event block
	if [[ "$line" =~ Event\ SYSMONEVENT ]]; then
		# If the previous buffer contains the search string, print it
		if [[ -n "$buffer" && "$buffer" == *"$search"* ]]; then
      echo "$bar"
      echo "$buffer"
		fi
		buffer="" # Reset buffer for the new block
	fi

	# Append current line to buffer
	buffer+="$line"$'\n'
done < "$log"

# Check the last block
if [[ -n "$buffer" && "$buffer" == *"$search"* ]]; then
  echo "$bar"
  echo "$buffer"
fi
