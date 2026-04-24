#!/usr/bin/env bash
set -euo pipefail

PKG_CSV="$HOME/Documents/pacmanpkgs.csv"

# FUNCTION: check_for_updates()
# Check for updates and additionally see if any affect AMD GPU
check_for_updates() {
    echo "Checking for updates..."

    local count=$(checkupdates | wc -l)

    if [ "$count" -ne 0 ]; then
        local gpu_detect

        echo "Updates available: $count"
        gpu_detect="$(checkupdates | awk '/cachyos|proton|nvidia|amd|wine|xorg|wayland|archlinux|faugus|steam|vulkan|firmware|drm/ {print $1, $4}')"
        if [ -n "${gpu_detect-}" ]; then
            echo "!!! FOUND THESE PACKAGES !!!"
            echo "$gpu_detect"
        fi
    else
        echo "No new packages. You're up-to-date!"
    fi
}

# FUNCTION: update_the_csv()
# Update the maintained package csv
update_the_csv() {
    local currentdate testing package version_info old_version new_version timestamp
    local temp_file="${PKG_CSV}.tmp"

    currentdate="$(date +"%Y-%m-%d")"

    # Extract today's upgrades from pacman.log
    # example output: [2026-04-22T15:40:17+1000] proton-cachyos-slr (1:10.0.20260408-1 -> 1:10.0.20260409-1)
    #                 $1                         $2                 $3                 $4 $5
    testing=$(awk "/$currentdate.*upgraded/{print \$1, \$4, \$5, \$6, \$7}" /var/log/pacman.log)

    if [ -n "${testing-}" ]; then

        # Process each upgraded package from today
        while IFS= read -r log_line; do
            # Extract timestamp (remove brackets) and convert to local time
            local raw_timestamp=$(echo "$log_line" | awk '{print $1}' | tr -d '[]')
            timestamp=$(date -d "$raw_timestamp" +"%Y-%m-%d %H:%M:%S")

            # Extract package name
            package=$(echo "$log_line" | awk '{print $2}')

            # Extract versions from "(old -> new)" format
            old_version=$(echo "$log_line" | awk '{print $3}' | tr -d '(')
            new_version=$(echo "$log_line" | awk '{print $5}' | tr -d ')')

            # Process the CSV file
            awk -v pkg="$package" -v new_v="$new_version" -v old_v="$old_version" -v ts="$timestamp" \
              '$0 ~ "^" pkg "," { $0 = pkg "," new_v "," old_v "," ts } 1' "$PKG_CSV" > "$PKG_CSV.tmp" && \
              mv "$PKG_CSV.tmp" "$PKG_CSV"
        done <<< "$testing"

        echo "CSV file updated with today's package upgrades."
        echo "to view, use 'cat Documents/pacmanpkgs.csv | column -s, -t | less'"
    else
        echo "Nothing was updated today."
    fi
    echo "Total installed packages        $(pacman -Q | wc -l)"
    echo "Explicitly installed packages   $(pacman -Qe | wc -l)"
}

# FUNCTION: sync_all_packages()
# Update the maintained pacakges csv for newly installed packages
sync_all_packages() {
    local temp_file="${PKG_CSV}.tmp"

    # Create new CSV with header
    echo "package_name,current_version,prev_version,last_updated" > "$temp_file"

    # Get all installed packages with their versions
    pacman -Q | while read -r package version; do
        # Check if package already exists in CSV
        if grep -q "^${package}," "$PKG_CSV"; then
            # Keep existing entry
            grep "^${package}," "$PKG_CSV" >> "$temp_file"
        else
            # Add new package with today's date
            echo "${package},${version},,unknown" >> "$temp_file"
        fi
    done

    mv "$PKG_CSV" "${PKG_CSV}.bak"
    mv "$temp_file" "$PKG_CSV"
    echo "CSV synced with all installed packages."
}

# FUNCTION: print_todays_updates()
# print a list of pkgs updated today (today's current date)
print_todays_updates() {
    echo "----------------------------------------------------------------------------------------------"
    grep "$(date +"%Y-%m-%d")" $PKG_CSV | column -s, -t
    echo "----------------------------------------------------------------------------------------------"
}

# FUNCTION: create_backups()
# Create a backup of cached packages if required
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
    do_upgraded_packages=false
    do_installed_packages=false
    do_print_todays=false

    # Parse options
    while getopts ":cbpsu" opt; do
        case $opt in
            c) do_checkupdate=true ;;
            b) do_backups=true ;;
            p) do_print_todays=true;;
            s) do_installed_packages=true ;;
            u) do_upgraded_packages=true ;;
            \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        esac
    done

    # Execute requested options
    $do_checkupdate && check_for_updates
    $do_installed_packages && sync_all_packages
    $do_upgraded_packages && update_the_csv
    $do_print_todays && print_todays_updates

    # If no flags provided, show usage
    if ! $do_backups && ! $do_checkupdate && ! $do_installed_packages && ! $do_upgraded_packages && ! $do_print_todays; then
        echo "Usage: $0 [-c] [-b] [-s] [-u]"
        echo " -c   Check for updates"
        echo " -b   Backup current cached pkgs"
        echo " -p   Print a list of upgraded packages from today"
        echo " -s   Sync the CSV file for newly installed"
        echo " -u   Update the maintained system package list CSV file"

    fi
}
main "$@"
