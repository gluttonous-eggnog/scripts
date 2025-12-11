#!/usr/bin/env bash

FILE="$HOME/Documents/pkg.lst"
BAK_FILE="${FILE}.bak"
OUTPUT_FILE="$HOME/Documents/updated-pkg.txt"

# Get the most recent Monday (today if it's Monday)
monday=$(date -d "last monday" +"%Y-%m-%d")
if [[ $(date +%u) -eq 1 ]]; then
    monday="$(date +"%Y-%m-%d")"
fi
currentdate="$(date +"%Y-%m-%d")"

echo "-------------------------------------------------------------"
echo "******* GET A LIST OF UPGRADED PKGS SINCE: $monday *******"
echo "-------------------------------------------------------------"
echo "Packages upgraded since: $monday" > "$OUTPUT_FILE"
echo >> "$OUTPUT_FILE"

# Convert start and end dates to timestamps
STARTD="$monday"
ENDD="$(date -d "$currentdate +1 day" +'%Y-%m-%d')"

# Query packages installed and save to file
echo "Querying packages installed since $monday"
expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | awk -v start="$STARTD" -v end="$ENDD" '$1 >= start && $1 <= end' > "$OUTPUT_FILE"
echo "Upgraded list saved to $OUTPUT_FILE"
echo "-------------------------------------------------------------"
echo "Update list of explicitly installed packages..."
echo "Querying using pacman -Qe since $monday"
rg -F -f <(pacman -Qe) "$OUTPUT_FILE" > "$FILE"
echo "Explicitly installed list save to $FILE"
echo "-------------------------------------------------------------"
