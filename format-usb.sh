#!/bin/bash
#
# format-usb.sh — Format a USB drive for use with RetroPie-ROMs-on-USB
#
# WARNING: This script performs DESTRUCTIVE operations. All data on the
# target device will be permanently erased. Use at your own risk.
#
set -euo pipefail

# ── Dry-run mode ────────────────────────────────────────────────────────
DRY_RUN=false

# ── Colors ──────────────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# ── Logging ─────────────────────────────────────────────────────────────
log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ── Safety ──────────────────────────────────────────────────────────────
confirm() {
    local prompt="${1:-Are you sure?}"
    local response
    read -r -p "$prompt [y/N] " response
    [[ "$response" =~ ^[Yy]$ ]]
}

# ── Device detection ────────────────────────────────────────────────────
detect_usb_devices() {
    log_info "Scanning for USB storage devices..."
    echo ""
    lsblk -d -o NAME,SIZE,TYPE,TRAN | grep -E 'usb|disk' || true
    echo ""
}

get_device_size() {
    local device="$1"
    lsblk -d -b -o SIZE,TYPE "/dev/$device" 2>/dev/null | awk '$2=="disk"{print $1}' || echo "0"
}

human_readable_size() {
    local bytes="$1"
    if command -v numfmt &>/dev/null; then
        numfmt --to=iec-i --suffix=B "$bytes"
    else
        echo "${bytes} bytes"
    fi
}

# ── Validation ──────────────────────────────────────────────────────────
validate_device() {
    local device="$1"

    if [[ -z "$device" ]]; then
        log_error "No device specified."
        return 1
    fi

    if [[ ! "$device" =~ ^[a-zA-Z0-9]+$ ]]; then
        log_error "Invalid device name: '$device'. Use short name (e.g., sdb, sdc)."
        return 1
    fi

    if [[ ! -b "/dev/$device" ]]; then
        log_error "Device '/dev/$device' does not exist or is not a block device."
        return 1
    fi

    # Prevent accidental formatting of system disks
    local device_type
    device_type=$(lsblk -d -o TYPE "/dev/$device" 2>/dev/null | tail -1 || echo "unknown")
    if [[ "$device_type" != "disk" ]]; then
        log_error "Device '/dev/$device' is not a disk (type: $device_type). Aborting."
        return 1
    fi

    # Check if it's a USB device
    local tran
    tran=$(lsblk -d -o TRAN "/dev/$device" 2>/dev/null | tail -1 || echo "unknown")
    if [[ "$tran" != "usb" ]]; then
        log_warn "Device '/dev/$device' may not be a USB device (transport: $tran)."
        if ! confirm "Continue anyway?"; then
            return 1
        fi
    fi

    return 0
}

# ── Filesystem formatting ───────────────────────────────────────────────
format_device() {
    local device="$1"
    local fstype="$2"
    local label="${3:-RETROPIE}"

    local size_bytes
    size_bytes=$(get_device_size "$device")
    local size_hr
    size_hr=$(human_readable_size "$size_bytes")

    log_warn "About to format /dev/$device ($size_hr) as $fstype with label '$label'."
    log_warn "ALL DATA ON THIS DEVICE WILL BE PERMANENTLY ERASED!"

    if ! confirm "Are you absolutely sure?"; then
        log_info "Aborted."
        return 1
    fi

    # Double-confirm for large drives (>32GB)
    if (( size_bytes > 34359738368 )); then
        log_warn "This is a large drive ($size_hr). Please verify it's the correct device."
        if ! confirm "Really format this drive?"; then
            log_info "Aborted."
            return 1
        fi
    fi

    case "$fstype" in
        fat32|vfat)
            log_info "Formatting /dev/$device as FAT32..."
            if [[ "$DRY_RUN" == true ]]; then
                echo -e "${YELLOW}[DRY-RUN]${NC} mkfs.vfat -F 32 -n $label /dev/$device"
            else
                mkfs.vfat -F 32 -n "$label" "/dev/$device"
            fi
            ;;
        ext2)
            log_info "Formatting /dev/$device as ext2..."
            if [[ "$DRY_RUN" == true ]]; then
                echo -e "${YELLOW}[DRY-RUN]${NC} mkfs.ext2 -L $label /dev/$device"
            else
                mkfs.ext2 -L "$label" "/dev/$device"
            fi
            ;;
        ext3)
            log_info "Formatting /dev/$device as ext3..."
            if [[ "$DRY_RUN" == true ]]; then
                echo -e "${YELLOW}[DRY-RUN]${NC} mkfs.ext3 -L $label /dev/$device"
            else
                mkfs.ext3 -L "$label" "/dev/$device"
            fi
            ;;
        ext4)
            log_info "Formatting /dev/$device as ext4..."
            if [[ "$DRY_RUN" == true ]]; then
                echo -e "${YELLOW}[DRY-RUN]${NC} mkfs.ext4 -L $label /dev/$device"
            else
                mkfs.ext4 -L "$label" "/dev/$device"
            fi
            ;;
        ntfs)
            log_info "Formatting /dev/$device as NTFS..."
            if [[ "$DRY_RUN" == true ]]; then
                echo -e "${YELLOW}[DRY-RUN]${NC} mkfs.ntfs -L $label -Q /dev/$device"
            else
                mkfs.ntfs -L "$label" -Q "/dev/$device"
            fi
            ;;
        *)
            log_error "Unsupported filesystem: $fstype"
            return 1
            ;;
    esac

    log_info "Format complete: /dev/$device ($fstype, label: $label)"
}

# ── Interactive menu ────────────────────────────────────────────────────
show_menu() {
    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║     RetroPie USB Format Tool             ║"
    echo "╠══════════════════════════════════════════╣"
    echo "║  1) FAT32  (recommended, max compatible) ║"
    echo "║  2) ext2                                  ║"
    echo "║  3) ext3                                  ║"
    echo "║  4) ext4  (Linux only)                    ║"
    echo "║  5) NTFS  (Windows compatible)            ║"
    echo "║  6) List USB devices                      ║"
    echo "║  7) Exit                                  ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                echo "Usage: $(basename "$0") [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -d, --dry-run    Show what would be done without making changes"
                echo "  -h, --help       Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  BE EXTREMELY CAREFUL!                                    ║"
    echo "║  I am not responsible for any loss of data or damage      ║"
    echo "║  to your system by running this script.                   ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log_warn "DRY-RUN mode enabled. No changes will be made."
        echo ""
    fi

    if [[ $EUID -ne 0 ]]; then
        log_warn "This script should be run as root for best results."
        if ! confirm "Continue without root?"; then
            exit 1
        fi
    fi

    detect_usb_devices

    while true; do
        show_menu
        read -r -p "Select option [1-7]: " choice

        case "$choice" in
            1|2|3|4|5)
                local fstype
                case "$choice" in
                    1) fstype="fat32" ;;
                    2) fstype="ext2" ;;
                    3) fstype="ext3" ;;
                    4) fstype="ext4" ;;
                    5) fstype="ntfs" ;;
                esac

                read -r -p "Enter device name (e.g., sdb): " device
                validate_device "$device" || continue

                read -r -p "Enter volume label [RETROPIE]: " label
                label="${label:-RETROPIE}"

                format_device "$device" "$fstype" "$label"
                ;;
            6)
                detect_usb_devices
                ;;
            7)
                log_info "Goodbye."
                exit 0
                ;;
            *)
                log_error "Invalid option: $choice"
                ;;
        esac
    done
}

main "$@"
