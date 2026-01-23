#!/bin/bash
#
# fanspeed.sh - Lenovo SA120 Fan Speed Controller
# For Synology DSM 7.x / Xpenology / Arc Loader
#
# Controls fan speed on Lenovo ThinkServer SA120 disk shelves
# using SCSI Enclosure Services (SES) via sg_ses.
#
# Usage: fanspeed.sh [OPTIONS] [SPEED]
#
# Requires: sg3_utils (provides sg_ses command)
#

set -e

# ============================================================================
# Configuration
# ============================================================================

# SES Protocol Constants
# Page 0x2 = Enclosure Status/Control page
SES_PAGE="0x2"

# Fan control elements start at byte offset 88 in page 0x2
# Each fan uses 4 bytes, there are 6 fans total
FAN_OFFSET_BASE=88
FAN_COUNT=6
FAN_BYTES=4

# Fan control byte encoding:
# Byte 0: 0x80 = Select bit (indicates this element should be modified)
# Byte 1: 0x00 = Reserved
# Byte 2: 0x00 = Reserved
# Byte 3: (1 << 5) | (speed & 0x07) = Request control + speed bits
#         Bit 5 = "Request control" flag
#         Bits 0-2 = Speed level (1-6)

# ============================================================================
# Functions
# ============================================================================

usage() {
    cat << 'EOF'
Usage: fanspeed.sh [OPTIONS] [SPEED]

Control fan speed on Lenovo ThinkServer SA120 disk shelves.

Options:
  -s, --status       Show current fan speeds without making changes
  -d, --device DEV   Use specific device (default: auto-detect)
  -q, --quiet        Suppress informational output
  -h, --help         Show this help message

Arguments:
  SPEED              Fan speed level 1-6
                     1 = Slowest (quietest)
                     6 = Fastest (loudest)

Examples:
  fanspeed.sh --status           # Check current fan speeds
  fanspeed.sh 2                  # Set all fans to speed 2 (quiet)
  fanspeed.sh -d /dev/sg6 1      # Set specific device to speed 1

Requirements:
  - sg3_utils package (provides sg_ses command)
  - Root privileges (sudo)

EOF
    exit 0
}

error() {
    echo "Error: $1" >&2
    exit 1
}

info() {
    if [[ "$QUIET" != "1" ]]; then
        echo "$1"
    fi
}

# Check if sg_ses is available
check_dependencies() {
    if ! command -v sg_ses &> /dev/null; then
        error "sg_ses not found. Install sg3_utils:
  Entware: opkg install sg3_utils
  Debian:  apt install sg3-utils"
    fi
}

# Find SA120 enclosure by scanning /dev/sg* devices
find_enclosure() {
    local found=""

    for dev in /dev/sg*; do
        [[ -e "$dev" ]] || continue

        # Try to identify the device
        if sg_ses "$dev" 2>/dev/null | grep -q "ThinkServerSA120"; then
            found="$dev"
            break
        fi
    done

    if [[ -z "$found" ]]; then
        error "No SA120 enclosure found. Check connections and try: sg_ses /dev/sgX"
    fi

    echo "$found"
}

# Read and display current fan speeds
show_status() {
    local device="$1"

    info "SA120 Enclosure: $device"
    info "----------------------------"

    for i in $(seq 0 $((FAN_COUNT - 1))); do
        # Read fan speed using SES "current output only" element
        local output
        output=$(sg_ses --index=coo,"$i" --get=1:2:11 "$device" 2>/dev/null) || {
            echo "Fan $i: ERROR (could not read)"
            continue
        }

        # Extract the speed value from output (first line, before any comma/space)
        local speed
        speed=$(echo "$output" | head -1 | awk '{print $1}')

        echo "Fan $i: $speed RPM"
    done
}

# Set fan speed for all fans
set_fan_speed() {
    local device="$1"
    local speed="$2"

    # Validate speed
    if [[ ! "$speed" =~ ^[1-6]$ ]]; then
        error "Speed must be 1-6 (got: $speed)"
    fi

    info "Setting all fans to speed $speed on $device..."

    # Read current page 0x2 data
    local raw_data
    raw_data=$(sg_ses -p "$SES_PAGE" "$device" --raw 2>/dev/null) || {
        error "Failed to read enclosure status page"
    }

    # Convert to array of hex bytes
    # shellcheck disable=SC2206
    local bytes=($raw_data)
    local total_bytes=${#bytes[@]}

    if [[ $total_bytes -lt $((FAN_OFFSET_BASE + FAN_COUNT * FAN_BYTES)) ]]; then
        error "Unexpected page size: $total_bytes bytes (expected at least $((FAN_OFFSET_BASE + FAN_COUNT * FAN_BYTES)))"
    fi

    # Calculate control byte value: (1 << 5) | (speed & 7)
    # Bit 5 = request control, bits 0-2 = speed
    local control_byte
    control_byte=$(printf "%02x" $(( (1 << 5) | (speed & 7) )))

    # Modify fan control bytes
    for i in $(seq 0 $((FAN_COUNT - 1))); do
        local offset=$((FAN_OFFSET_BASE + i * FAN_BYTES))

        # Set 4-byte fan control element:
        # [0x80, 0x00, 0x00, control_byte]
        bytes[$offset]="80"
        bytes[$((offset + 1))]="00"
        bytes[$((offset + 2))]="00"
        bytes[$((offset + 3))]="$control_byte"
    done

    # Format bytes for sg_ses input (16 bytes per line, space-separated)
    local formatted=""
    local count=0

    for byte in "${bytes[@]}"; do
        formatted+="$byte"
        count=$((count + 1))

        if [[ $((count % 16)) -eq 0 ]]; then
            formatted+=$'\n'
        elif [[ $((count % 8)) -eq 0 ]]; then
            formatted+="  "
        else
            formatted+=" "
        fi
    done
    formatted+=$'\n'

    # Send control page
    echo "$formatted" | sg_ses -p "$SES_PAGE" "$device" --control --data - 2>/dev/null || {
        error "Failed to set fan speed"
    }

    info "Fan speed set to $speed"

    # Wait for fans to adjust and show new speeds
    if [[ "$QUIET" != "1" ]]; then
        info ""
        info "Waiting 5 seconds for fans to adjust..."
        sleep 5
        show_status "$device"
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    local device=""
    local speed=""
    local status_only=0
    QUIET=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            -s|--status)
                status_only=1
                shift
                ;;
            -d|--device)
                [[ -z "$2" ]] && error "Option --device requires an argument"
                device="$2"
                shift 2
                ;;
            -q|--quiet)
                QUIET=1
                shift
                ;;
            -*)
                error "Unknown option: $1"
                ;;
            *)
                if [[ -z "$speed" ]]; then
                    speed="$1"
                else
                    error "Unexpected argument: $1"
                fi
                shift
                ;;
        esac
    done

    # Check dependencies
    check_dependencies

    # Auto-detect device if not specified
    if [[ -z "$device" ]]; then
        info "Scanning for SA120 enclosure..."
        device=$(find_enclosure)
        info "Found: $device"
        info ""
    fi

    # Verify device exists
    [[ -e "$device" ]] || error "Device not found: $device"

    # Execute requested action
    if [[ $status_only -eq 1 ]]; then
        show_status "$device"
    elif [[ -n "$speed" ]]; then
        set_fan_speed "$device" "$speed"
    else
        # No action specified - show status
        show_status "$device"
    fi
}

main "$@"
