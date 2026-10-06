#!/bin/bash
set -euo pipefail

# format-usb.sh - Format a USB drive with a chosen filesystem
# Usage: ./format-usb.sh [device]
# Example: ./format-usb.sh /dev/sdb1

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME

# Colors for output
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log_info()  { echo -e "${YELLOW}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

cleanup() {
    # Restore terminal if interrupted
    stty echo 2>/dev/null || true
}
trap cleanup EXIT INT TERM

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [DEVICE]

Format a USB drive with a chosen filesystem.

Arguments:
  DEVICE    The device to format (e.g., /dev/sdb1). If not provided,
            you will be prompted to identify it.

Examples:
  ${SCRIPT_NAME} /dev/sdb1
  ${SCRIPT_NAME}

WARNING: This will DESTROY ALL DATA on the target device.
         Double-check the device before proceeding.
EOF
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)."
        exit 1
    fi
}

validate_device() {
    local device="$1"
    if [[ ! -b "$device" ]]; then
        log_error "Device '$device' is not a valid block device."
        exit 1
    fi
    # Prevent accidental formatting of system disks
    if findmnt -n -o SOURCE --target / | grep -q "^${device}"; then
        log_error "Refusing to format the root filesystem device: $device"
        exit 1
    fi
}

list_devices() {
    log_info "Available block devices:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL
    echo
}

confirm_action() {
    local device="$1"
    echo
    log_error "WARNING: This will DESTROY ALL DATA on $device!"
    read -rp "Are you sure you want to continue? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) ;;
        *) log_info "Aborted."; exit 0 ;;
    esac
}

select_filesystem() {
    local fs
    echo
    echo "Select filesystem type:"
    echo "  1) FAT32  (most compatible, recommended for RetroPie)"
    echo "  2) ext2"
    echo "  3) ext3"
    echo "  4) ext4"
    echo "  5) JFS"
    echo "  6) NTFS"
    echo "  7) XFS"
    echo "  8) ReiserFS"
    echo
    read -rp "Enter choice [1-8]: " fs
    echo "$fs"
}

format_device() {
    local device="$1"
    local fs_choice="$2"
    local fs_type
    local fs_label="RETROPIE"

    case "$fs_choice" in
        1) fs_type="vfat" ;;
        2) fs_type="ext2" ;;
        3) fs_type="ext3" ;;
        4) fs_type="ext4" ;;
        5) fs_type="jfs" ;;
        6) fs_type="ntfs" ;;
        7) fs_type="xfs" ;;
        8) fs_type="reiserfs" ;;
        *) log_error "Invalid choice: $fs_choice"; exit 1 ;;
    esac

    log_info "Formatting $device as $fs_type..."

    case "$fs_type" in
        vfat)
            mkfs.vfat -F 32 -n "$fs_label" "$device"
            ;;
        ext2|ext3|ext4)
            mkfs."$fs_type" -L "$fs_label" "$device"
            ;;
        jfs)
            mkfs.jfs -L "$fs_label" -q "$device"
            ;;
        ntfs)
            mkfs.ntfs -L "$fs_label" -Q "$device"
            ;;
        xfs)
            mkfs.xfs -L "$fs_label" -f "$device"
            ;;
        reiserfs)
            mkfs.reiserfs -l "$fs_label" -q "$device"
            ;;
    esac

    log_info "Format complete: $device ($fs_type)"
}

main() {
    local device="${1:-}"

    check_root

    if [[ -z "$device" ]]; then
        list_devices
        read -rp "Enter the device to format (e.g., /dev/sdb1): " device
    fi

    validate_device "$device"
    confirm_action "$device"

    local fs_choice
    fs_choice=$(select_filesystem)
    format_device "$device" "$fs_choice"
}

main "$@"
