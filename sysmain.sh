#!/usr/bin/env bash
set -euo pipefail

PKG_CSV="$HOME/Documents/pacmanpkgs.csv"

# Check for updates and additionally see if any affect AMD GPU
check_for_updates() {
    echo "Checking for updates..."

    local count=$(checkupdates | wc -l)

    if [ "$count" -ne 0 ]; then
        echo "Updates available: $count"
        # detect AMD GPU related packages
        local test amdgpu_detect
        test=$(checkupdates)
        amdgpu_detect="$(echo "$test" | awk '/mesa|vulkan|amd|radeon|rocm|amdgpu|firmware|drm|xf86-video-amdgpu/ {print $1, $4}')"
        if [ -z "${amdgpu_detect-}" ]; then
            echo "No AMD GPU related packages found"
            echo "Checking for CachyOS, proton, wine, xorg, etc..."
            echo "$test" | awk '/cachyos|proton|wine|xorg|wayland|archlinux|faugus|steam/ {print $1, $4}'
        else
            echo "!!! FOUND THESE PACKAGES !!!"
            echo "$amdgpu_detect"
        fi
    else
        echo "No new packages. You're up-to-date!"
    fi
}

# Update the maintained package csv
update_the_csv() {
    local currentdate test package version_info old_version new_version timestamp
    local temp_file="${PKG_CSV}.tmp"

    currentdate="$(date +"%Y-%m-%d")"

    # Extract today's upgrades from pacman.log
    # example output: [2026-04-22T15:40:17+1000] proton-cachyos-slr (1:10.0.20260408-1 -> 1:10.0.20260409-1)
    #                 $1                         $2                 $3                 $4 $5
    test=$(awk "/$currentdate.*upgraded/{print \$1, \$3, \$4, \$5, \$6}" /var/log/pacman.log)

    if [ -n "${test-}" ]; then
        # Create temporary file starting with the header
        head -n 1 "$PKG_CSV" > "$temp_file"

        # Process each upgraded package from today
        while IFS= read -r log_line; do
            # Extract timestamp (remove brackets) and convert to local time
            local raw_timestamp=$(echo "$log_line" | awk '{print $1}' | tr -d '[]')
            timestamp=$(date -d "$raw_timestamp" +"%Y-%m-%d")

            # Extract package name
            package=$(echo "$log_line" | awk '{print $2}')

            # Extract versions from "(old -> new)" format
            old_version=$(echo "$log_line" | awk '{print $3}' | tr -d '(')
            new_version=$(echo "$log_line" | awk '{print $5}' | tr -d ')')

            # Process the CSV file
            awk -v pkg="$package" -v new_ver="$new_version" -v old_ver="$old_version" \
                -v ts="$timestamp" 'NR==1 {print; next}
                $1==pkg {print $1","new_ver","old_ver","ts; next}
                {print}' "$PKG_CSV" >> "$temp_file"

            # Replace original file with updated version
            echo "Creating a backup of $PKG_CSV"
            mv "$PKG_CSV" "${PKG_CSV}.bak"
            mv "$temp_file" "$PKG_CSV"

        done <<< "$test"

        echo "CSV file updated with today's package upgrades."
    else
        echo "Nothing was updated today."
    fi
    echo "Total installed packages        $(pacman -Q | wc -l)"
    echo "Explicitly installed packages   $(pacman -Qe | wc -l)"
}

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
            echo "${package},${version},,$(date +"%Y-%m-%d")" >> "$temp_file"
        fi
    done

    echo "Creating a backup of $PKG_CSV"
    mv "$PKG_CSV" "${PKG_CSV}.bak"
    mv "$temp_file" "$PKG_CSV"
    echo "CSV synced with all installed packages."
}


# MAIN script starts here:
main() {
    do_checkupdate=false
    do_backups=false
    do_upgraded_packages=false
    do_installed_packages=false

    # Parse options
    while getopts ":cbsu" opt; do
        case $opt in
            c) do_checkupdate=true ;;
            b) do_backups=true ;;
            s) do_installed_packages=true ;;
            u) do_upgraded_packages=true ;;
            \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        esac
    done

    # Execute requested options
    $do_checkupdate && check_for_updates
    $do_installed_packages && sync_all_packages
    $do_upgraded_packages && update_the_csv

    # If no flags provided, show usage
    if ! $do_backups && ! $do_checkupdate && ! $do_installed_packages && ! $do_upgraded_packages; then
        echo "Usage: $0 [-c] [-b] [-s] [-u]"
        echo " -c   Check for updates"
        echo " -b   Backup current cached pkgs"
        echo " -s   Update the maintained system package list CSV file"
        echo " -u   Sync the CSV file for newly installed"
    fi
}
main "$@"
