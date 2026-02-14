#!/bin/bash
# Scan sysmon log for events

# Inputs
log="/dev/stdin" # Pipe the log to this script 
sfile="scanEvents.txt" # Saved scans

# Parameters
color='\e[91m'
colorB='\e[34m'
rst='\e[0m'

# If the log has not been scanned then scan it
if [ ! -f "$sfile" -o  ! -f "$sfile" ]; then
echo -e "Scanning log"
echo -e "* Saving scan at: $colorB$sfile$rst"
counter=0

# Buffer for each event
buffer=""

while IFS= read -r line; do
  # Start of new event
  if [[ "$line" =~ Event\ SYSMONEVENT ]]; then
    # Save previous event
    if [[ -n "$buffer" ]]; then
      echo "$buffer" >> "$sfile"
      counter=$((counter + 1))
      buffer=""
    fi
  fi
  # Append current line to buffer
  buffer+="$line"$'\n'
done < "$log"

# Save last event
if [[ -n "$buffer" ]]; then
  echo "$buffer" >> "$sfile"
  counter=$((counter + 1))
fi
echo -e "Total Events: $color$counter$rst"
fi


# Search doc
search="$1"
if [[ -z "$search" ]]; then
    echo "Usage: $0 <search_text>"
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
        # Reset buffer for the new block
        buffer=""
    fi

    # Append current line to buffer
    buffer+="$line"$'\n'
done < "$sfile"

# Check the last block
if [[ -n "$buffer" && "$buffer" == *"$search"* ]]; then
        echo "$bar"
        echo "$buffer"
fi



