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
    else
        echo "No new packages. System is up-to-date!"
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
    local currentdate test

    currentdate="$(date +"%Y-%m-%d")"
    test=$(awk "/$currentdate.*upgraded/{print \$4, \$5, \$6, \$7}" /var/log/pacman.log)
    if [ -n "${test-}" ]; then
        echo "--------------------------------------------------------"
        echo "$test"
        echo "--------------------------------------------------------"
    else
        echo "Total Installed Pacakges      $(pacman -Q | wc -l)"
        echo "Explicitly Installed Packages $(pacman -Qe | wc -l)"
    fi
}

# create lists of packages installed from monday of this current week
create_pacman_lists() {
    local currentdate monday ENDD

    currentdate="$(date +"%Y-%m-%d")"
    # Convert start and end dates to timestamps
    monday="$(get_monday)"
    ENDD="$(date -d "$currentdate +1 day" +'%Y-%m-%d')"
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
    local src dst files

    src="/var/cache/pacman/pkg"
    dst="$HOME/Documents/"
    files=("$src"/*)
    if (( ${#files[@]} )); then
        mv -- "${files[@]}" "$dst"/
    else
        echo "No files to move in $src"
    fi
}

# MAIN script starts here:
main() {
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

    # If no flags provided, show usage
    if ! $do_backups && ! $do_checkupdate && ! $do_package_list_files && ! $do_print_today; then
        echo "Usage: $0 [-c] [-b] [-l] [-p]"
        echo " -c   Check for updates"
        echo " -b   Backup current cached pkgs"
        echo " -l   Create lists of updated packages from pacman.log"
        echo " -p   Print packages updated today"
    fi
}
main "$@"
