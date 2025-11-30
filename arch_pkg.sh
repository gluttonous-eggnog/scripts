#!/usr/bin/env bash

FILE="$HOME/Documents/pkg.lst"
BAK_FILE="${FILE}.bak"

echo "** Update list of explicitly installed packages **"
if [ -f "$FILE" ]; then
    # Check if the backup exists
    if [ -f "$BAK_FILE" ]; then

        # Get current time and last modified time of the backup in seconds since epoch
        CURRENT_TIME=$(date +%s)
        BAK_MOD_TIME=$(stat -c %Y "$BAK_FILE")

        # Calculate the difference in days
        DIFF_DAYS=$(( (CURRENT_TIME - BAK_MOD_TIME) / 86400 ))

        if [ "$DIFF_DAYS" -gt 2 ]; then
            echo "Backup is older than 2 days. Overwriting..."
            cp "$FILE" "$BAK_FILE"
        else
            echo "Backup is recent (less than or equal to 2 days). No action taken."
        fi

    else
        echo "No backup file found. Creating backup..."
        cp "$FILE" "$BAK_FILE"
    fi

    # Now update the package list
    echo "Updating '$FILE' now.."
    pacman -Qe > "$FILE"
    echo "Done."

else
    echo "File '$FILE' does not exist. Creating now..."
    pacman -Qe > "$FILE"
fi

# Now update recently updated packages for potential partial upgrade fails
# Get the most recent Monday (today if it's Monday)
monday=$(date -d "last monday" +"%Y-%m-%d")
if [[ $(date +%u) -eq 1 ]]; then
    monday=$(date +"%Y-%m-%d")
fi
currentdate=$(date +"%Y-%m-%d")

echo "*****************************************************"
echo "*** GET A LIST OF UPGRADED PKGS SINCE: $monday ***"
echo "*****************************************************"

OUTPUT_FILE="$HOME/Documents/updated-pkg.txt"

echo "Packages upgraded since: $monday" > "$OUTPUT_FILE"
echo >> "$OUTPUT_FILE"

# Convert start and end dates to timestamps
STARTD=$(date -d "$monday" +%s)
ENDD=$(date -d "$currentdate +1 day" +%s)

# Query packages installed and save to file
echo "Querying packages installed since $monday"
expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | awk -v start="$monday" -v end="$currentdate" '($1 >= start && $1 <= end)' >> "$OUTPUT_FILE"
echo "Upgraded list saved to $OUTPUT_FILE"
