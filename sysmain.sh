#!/usr/bin/env bash
set -euo pipefail

ELST_FILE="$HOME/Documents/exp_pkg.lst"
OUTPUT_FILE="$HOME/Documents/all_pkg.txt"

# Check for updates and additionally see if any affect AMD GPU
check_for_updates() {
    echo "Checking for updates..."
    local count=$(checkupdates | wc -l)
    if [ "$count" -ne 0 ]; then
        echo "Updates available: $count"
        # detect AMD GPU related packages
        local test=$(checkupdates)
        local amdgpu_detect="$(echo $test | awk '/mesa|vulkan|amd|radeon|rocm|amdgpu|firmware|drm|xf86-video-amdgpu/ {print $3, $4}')"
        if [ -z "$amdgpu_detect" ]; then
            echo "No AMD GPU related packages found"
        else
            echo "!!! FOUND THESE PACKAGES !!!"
            echo "$amdgpu_detect"
        fi
    else
        echo "No new packages. You're up-to-date!"
    fi
}

# Get the most recent Monday (today if it's Monday)
get_monday() {
    local monday
    if [[ $(date +%u) -eq 1 ]]; then
        monday="$(date +"%Y-%m-%d")"
    else
        monday=$(date -d "last monday" +"%Y-%m-%d")
    fi
    echo "$monday"
}

# print a list of pkgs updated today (today's current date)
print_todays_updates() {
    local currentdate="$(date +"%Y-%m-%d")"
    echo "--------------------------------------------------------"
    awk "/$currentdate.*upgraded/{print \$4, \$5, \$6, \$7}" /var/log/pacman.log
    echo "--------------------------------------------------------"
}

# create lists of packages installed from monday of this current week
create_pacman_lists() {
    local currentdate="$(date +"%Y-%m-%d")"
    # Convert start and end dates to timestamps
    local monday="$(get_monday)"
    local ENDD="$(date -d "$currentdate +1 day" +'%Y-%m-%d')"
    echo ">> GET A LIST OF UPGRADED PKGS SINCE: $monday"
    # Query packages installed and save to file
    echo "Querying packages installed since $monday"
    expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | awk -v start="$monday" -v end="$ENDD" '$1 >= start && $1 <= end' > "$OUTPUT_FILE"
    echo "...done."
    echo ">>|Upgraded list now saved to $OUTPUT_FILE"
    echo "Updating list of explicitly installed packages since $monday"
    echo "...done."
    rg -F -f <(pacman -Qe) "$OUTPUT_FILE" > "$ELST_FILE"
    echo ">>|Explicitly installed now list save to $ELST_FILE"
}

# create backups of the cached updated pkgs
create_backups() {
    local src="/var/cache/pacman/pkg"
    local dst="$HOME/Documents/"
    local files=("$src"/*)
    if (( ${#files[@]} )); then
        mv -- "${files[@]}" "$dst"/
    else
        echo "No files to move in $src"
    fi
}

# MAIN script starts here:
do_checkupdate=false
do_backups=false
do_package_list_files=false
do_print_today=false


# Parse options
while getopts ":cblp" opt; do
    case $opt in
        c) do_checkupdate=true ;;
        b) do_backups=true ;;
        l) do_package_list_files=true ;;
        p) do_print_today=true ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
done

# Execute requested options
$do_checkupdate && check_for_updates
$do_package_list_files && create_pacman_lists
$do_print_today && print_todays_updates
#$do_backups && create_backups

# If no flags provided, show usage
if ! $do_backups && ! $do_checkupdate && ! $do_package_list_files && ! $do_print_today; then
    echo "Usage: $0 [-c] [-b] [-l]"
    echo " -c   Check for updates"
    echo " -b   Run backups"
    echo " -l   Create lists of updated packages from pacman.log"
    echo " -p   Print packages updated today"
fi
