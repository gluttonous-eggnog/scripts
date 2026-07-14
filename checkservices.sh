#!/usr/bin/env bash
set -euo pipefail

SRVCS_R="$HOME/Documents/_servicesR.bak"
SRVCS_A="$HOME/Documents/_servicesA.bak"

# FUNCTION: check_runnning_srvcs()
# Check and compare against prev list of running services
check_runnning_srvcs() {
    local testing="$(systemctl list-units --type=service --state=running --no-pager)"
    if [ -n "${testing-}" ]; then
        # check if prev saved list exists and compare
        if [ -f "$SRVCS_R" ]; then
            diff <(echo "$testing") "$SRVCS_R" -y --suppress-common-lines
        else
            echo "$testing" > "$SRVCS_R" && echo "Created $SRVCS_R"
        fi
    fi
}

# FUNCTION: check_all_srvcs()
# Check and compare against pre list of all known services
check_all_srvcs() {
    local testing="$(systemctl list-unit-files --type=service)"
    if [ -n "${testing-}" ]; then
        # check if prev saved list exists and compare
        if [ -f "$SRVCS_A" ]; then
            diff <(echo "$testing") "$SRVCS_A" -y --suppress-common-lines
        else
            echo "$testing" > "$SRVCS_A" && echo "Created $SRVCS_A"
        fi
    fi
}

# MAIN script starts here:
main() {
    do_running_srvcs=false
    do_all_srvcs=false

    # Parse options
    while getopts ":ar" opt; do
        case $opt in
            a) do_all_srvcs=true ;;
            r) do_running_srvcs=true ;;
            \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        esac
    done

    # Execute requested options
    $do_running_srvcs && check_runnning_srvcs
    $do_all_srvcs && check_all_srvcs

    if ! $do_running_srvcs && ! $do_all_srvcs; then
        echo "Usage: $0 [-a] [-r]"
        echo " -a   Check all services"
        echo " -r   Check running services"
    fi
}
main "$@"
