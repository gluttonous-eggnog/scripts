#!/usr/bin/env bash
set -euo pipefail

PKG_CSV="$HOME/Documents/pacmanpkgs.csv"

# FUNCTION: check_for_updates()
# Check for updates and additionally see if any affect GPU
check_for_updates() {
    echo "Checking for updates..."
    local listavailableupdates="$(checkupdates)"

    if [ -n "${listavailableupdates-}" ]; then
        echo "Updates available: $(wc -l <<< "$listavailableupdates")"
        local gpu_detect="$(checkupdates | awk '/cachyos|proton|nvidia|amd|wine|xorg|wayland|archlinux|faugus|steam|vulkan|firmware|drm/ {print $1, $4}')"
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
    local currentdate testing temp_file
    currentdate="$(date +"%Y-%m-%d")"
    temp_file="${PKG_CSV}.tmp"

    # 1. Extract today's upgrades into a temporary format: package,new_version,old_version,timestamp
    # Use gsub to clean brackets and parentheses directly in awk
    testing=$(awk -v d="$currentdate" '
        $0 ~ d ".*upgraded" {
            ts = $1; gsub(/[\[\]]/, "", ts);
            pkg = $2;
            old_v = $3; gsub(/\(/, "", old_v);
            new_v = $5; gsub(/\)/, "", new_v);
            print pkg "," new_v "," old_v "," ts
        }' /var/log/pacman.log)

    if [ -n "${testing-}" ]; then
        # 2. Update the CSV in ONE pass
        # Pass the extracted updates as a variable and use an associative array to track them
        awk -v updates_str="$testing" '
            BEGIN {
                FS = ","; OFS = ",";
                # Split the updates string into an array indexed by package name
                n = split(updates_str, lines, "\n");
                for (i = 1; i <= n; i++) {
                    split(lines[i], parts, ",");
                    update_data[parts[1]] = lines[i];
                }
            }
            {
                # If the first column (package) is in our update list, replace the whole line
                if ($1 in update_data) {
                    $0 = update_data[$1];
                }
                print $0
            }' "$PKG_CSV" > "$temp_file" && mv "$temp_file" "$PKG_CSV"

        echo "Updated $PKG_CSV."
    else
        echo "Nothing was upgraded today."
    fi
    echo "To view, use 'column -s, -t $PKG_CSV | less'"
}

# FUNCTION: sync_all_packages()
# Update the maintained pacakges csv for newly installed packages
sync_all_packages() {
    # Check if PKG_CSV exists
    if [ -f "$PKG_CSV" ]; then
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
                # Assuming package was only ever installed and not updated recently
                # Get the install date (use 2>/dev/null to suppress error output if not found)
                install_date=$(date -d "$(pacman -Qi "$package" 2>/dev/null | grep "Install Date" | sed 's/.*: //')" "+%Y-%m-%d %H:%M:%S")
                echo "${package},${version},,${install_date}" >> "$temp_file"
            fi
        done

        # Create a backup of original CSV file
        mv "$PKG_CSV" "${PKG_CSV}.bak" && echo "$PKG_CSV backup created."
        # make this the new official CSV file
        mv "$temp_file" "$PKG_CSV" && echo "$PKG_CSV synced with all installed packages."
    else
        echo "Create $PKG_CSV and add:"
        echo "'package_name,current_version,prev_version,last_updated'"
        echo "Save file, then re-run this script with -s flag"
    fi
}

# FUNCTION: print_todays_updates()
# print a list of pkgs updated today (today's current date)
print_todays_updates() {
    local explicit nativenondep diff testing

    testing=$( (grep "$(date +"%Y-%m-%d")" $PKG_CSV | column -s, -t) || true )
    if [ -n "${testing-}" ]; then
        echo "----------------------------------------------------------------------------------------------------------------"
        echo "$testing"
        echo "----------------------------------------------------------------------------------------------------------------"
    fi

    explicit=$(pacman -Qqe | wc -l)
    nativenondep=$(pacman -Qqent | wc -l)
    diff=$(( explicit - nativenondep ))
    echo "$(pacman -Qq | wc -l) packages installed"
    printf "%4s packages explicitly installed (of which %s are dependencies)\n" $explicit $diff
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

# FUNCTION: check_cachyosmirrors()
# Check the CachyOS mirrors API for partial or error status against top 10 mirror list in system
check_cachyosmirrors(){
    local mirrorsAPI systemMirrorsListing jsonExtract

    mirrorsAPI="https://packages.cachyos.org/api/v1/mirrors"
    jsonExtract=$(curl -s "$mirrorsAPI" | jq -r '.mirrors[] | select(.overall_status == "error" or .overall_status == "partial") | .url')

    if [ -n "${jsonExtract-}" ]; then
        echo "Checking CachyOS mirrors..."
        systemMirrorsListing=$(grep -m10 '^Server' /etc/pacman.d/cachyos-mirrorlist | awk -F' = ' '{print $2}')
        if [ -n "${systemMirrorsListing-}" ]; then
            while IFS= read -r url; do
                baseURL=$(echo "$url" | sed 's|\(.*cachyos/repo/\).*|\1|')

                if echo "$jsonExtract" | grep -Fq "$baseURL"; then
                    printf "\e[31mWARNING:\t%s\e[0m\n" $baseURL
                else
                    printf "HEALTHY:\t%s\n" $baseURL
                fi
            done <<< "$systemMirrorsListing"
        fi
    else
        echo "All mirrors look healthy."
    fi
}

# FUNCTION: print_usage()
# Print a list of accepted cmd line arguement options
print_usage(){
    echo "Usage: $0 [-c] [-b] [-m] [-s] [-u]"
    echo " -c   Check for updates"
    echo " -b   Backup current cached pkgs"
    echo " -m   Check status of CachyOS mirrors"
    echo " -p   Print a list of upgraded packages from today"
    echo " -s   Sync the CSV file for newly installed"
    echo " -u   Update the maintained system package list CSV file"
}

# MAIN
# script starts here:
main() {
    do_checkupdate=false
    do_backups=false
    do_upgraded_packages=false
    do_installed_packages=false
    do_print_todays=false
    do_cachy_mirror_check=false

    # Parse options
    while getopts ":cbmpsu" opt; do
        case $opt in
            c) do_checkupdate=true ;;
            b) do_backups=true ;;
            m) do_cachy_mirror_check=true ;;
            p) do_print_todays=true ;;
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
    $do_cachy_mirror_check && check_cachyosmirrors

    # If no flags provided, show usage
    if ! $do_backups && ! $do_checkupdate && ! $do_installed_packages && ! $do_upgraded_packages && ! $do_print_todays && ! $$do_cachy_mirror_check; then
        print_usage
    fi
}
main "$@"
