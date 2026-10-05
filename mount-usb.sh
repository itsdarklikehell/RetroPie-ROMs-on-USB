#!/bin/bash
#
# mount-usb.sh — Configure USB drive mounting for RetroPie-ROMs-on-USB
#
# Supports three methods:
#   automatic  — RetroPie's built-in USB ROM transfer service
#   manual     — fstab-based mounting with UUID
#   symlink   — Move RetroPie folder to USB and symlink back
#
set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# ── Logging ─────────────────────────────────────────────────────────────
log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step()  { echo -e "${BLUE}[STEP]${NC} $*"; }

# ── Config ──────────────────────────────────────────────────────────────
RETP_FOLDER="${RETP_FOLDER:-/home/pi/RetroPie}"
MNTPNT="${MNTPNT:-/media/usb0}"
MOUNT_USER="${MOUNT_USER:-pi}"
DRY_RUN=false

# ── Helpers ─────────────────────────────────────────────────────────────
confirm() {
    local prompt="${1:-Are you sure?}"
    local response
    read -r -p "$prompt [y/N] " response
    [[ "$response" =~ ^[Yy]$ ]]
}

run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        "$@"
    fi
}

detect_usb_devices() {
    log_info "Scanning for USB storage devices..."
    echo ""
    lsblk -o NAME,SIZE,TYPE,TRAN,MOUNTPOINT | grep -E 'usb|disk|part' || true
    echo ""
}

find_usb_mount() {
    # Find the first mounted USB partition
    lsblk -o NAME,TRAN,MOUNTPOINT -n -l | awk '$2=="usb" && $3!=""{print $3; exit}' || true
}

get_uuid() {
    local device="$1"
    lsblk -o UUID "/dev/$device" -n | head -1 || true
}

get_fstype() {
    local device="$1"
    lsblk -o FSTYPE "/dev/$device" -n | head -1 || true
}

# ── Method: Automatic ───────────────────────────────────────────────────
method_automatic() {
    log_step "Automatic Mount (Easiest Method)"
    echo ""
    echo "As of December 30, 2016 a simple automated method was added to run ROMs from a USB drive."
    echo ""
    echo "1. First Update the RetroPie Setup Script"
    echo "2. Re-Enable the USB ROM Transfer Service"
    echo "3. Format your USB drive to FAT32 (format-usb.sh)"
    echo "4. Create a folder called 'retropie-mount' on the USB drive"
    echo "5. Plug into Raspberry Pi"
    echo "6. It will proceed to automatically copy the RetroPie folder AND all of its contents"
    echo "   (you may need to reboot to start the copying)"
    echo ""
    log_warn "If you have a large ROM collection already on the SD card it will copy all of the ROMs too."
    log_warn "Make sure your USB is large enough. It is easiest if you haven't added any ROMs yet."
    echo ""
    echo "Once the folder structure is copied over the USB will be mounted over the RetroPie folder"
    echo "so any ROMs you add to your pi will be run off of the USB."
    echo ""

    if confirm "Open RetroPie Setup to enable USB ROM Service?"; then
        if command -v retropie_setup.sh &>/dev/null; then
            run_cmd sudo retropie_setup.sh
        else
            log_warn "retropie_setup.sh not found. Please run it manually from EmulationStation."
        fi
    fi
}

# ── Method: Manual ──────────────────────────────────────────────────────
method_manual() {
    log_step "Manual Mount (fstab-based)"
    echo ""
    echo "After formatting your USB (format-usb.sh):"
    echo ""

    # Step 1: Disable USB transfer daemon
    log_info "Step 1: Disable USB transfer daemon"
    echo "   Enter the RetroPie Setup menu within the RetroPie menu in EmulationStation."
    echo "   Select Setup / Tools."
    echo "   Select 'usbromservice - USB ROM Service'"
    echo "   Disable USB ROM Service."
    echo ""

    # Step 2: Plug in USB
    log_info "Step 2: Plug in USB drive"
    echo "   This can be done when the system is powered on."
    echo ""

    # Step 3: Transfer RetroPie folder
    log_info "Step 3: Transfer the existing RetroPie file structure"
    echo "   This step is mandatory regardless of whether you have any ROMs on your system."
    echo "   RetroPie has a specific directory structure and a number of files required"
    echo "   packaged with even empty installations."
    echo ""

    detect_usb_devices

    local usb_mount
    usb_mount=$(find_usb_mount)
    if [[ -n "$usb_mount" ]]; then
        log_info "Detected USB mount point: $usb_mount"
    else
        read -r -p "Enter USB mount point [$MNTPNT]: " usb_mount
        usb_mount="${usb_mount:-$MNTPNT}"
    fi

    echo ""
    echo "To move the RetroPie folder, run:"
    echo "  sudo mv -v $RETP_FOLDER/* $usb_mount/"
    echo ""
    log_warn "Make sure $usb_mount is correct before running the above command!"
    echo ""

    if confirm "Execute the move command now?"; then
        run_cmd sudo mv -v "$RETP_FOLDER"/* "$usb_mount/"
        log_info "Files moved successfully."
    else
        log_info "Skipped. You can run the command manually later."
    fi
    echo ""

    # Step 4: Configure fstab
    log_info "Step 4: Configure fstab to automatically mount USB drive"
    echo ""
    echo "Establish the drive's UUID number by entering the command:"
    echo "  ls -l /dev/disk/by-uuid/"
    echo ""

    local device
    read -r -p "Enter USB device name (e.g., sda1): " device
    if [[ -z "$device" ]]; then
        log_error "No device specified. Skipping fstab configuration."
        return 1
    fi

    local uuid
    uuid=$(get_uuid "$device")
    if [[ -z "$uuid" ]]; then
        log_error "Could not determine UUID for /dev/$device. Skipping fstab configuration."
        return 1
    fi

    local fstype
    fstype=$(get_fstype "$device")
    fstype="${fstype:-vfat}"

    log_info "Device: /dev/$device"
    log_info "UUID: $uuid"
    log_info "Filesystem: $fstype"
    echo ""

    local fstab_line
    case "$fstype" in
        vfat|fat32)
            fstab_line="UUID=$uuid\t$RETP_FOLDER\tvfat\tnofail,user,uid=$MOUNT_USER,gid=$MOUNT_USER\t0\t2"
            ;;
        ext4|ext3|ext2)
            fstab_line="UUID=$uuid\t$RETP_FOLDER\t$fstype\tnofail,defaults\t0\t0"
            ;;
        ntfs)
            fstab_line="UUID=$uuid\t$RETP_FOLDER\tntfs-3g\tnofail,user,uid=$MOUNT_USER,gid=$MOUNT_USER\t0\t0"
            ;;
        *)
            fstab_line="UUID=$uuid\t$RETP_FOLDER\t$fstype\tnofail,defaults\t0\t0"
            ;;
    esac

    echo "Add this line to /etc/fstab:"
    echo "  $fstab_line"
    echo ""
    log_warn "Note: each item is TAB delimited. If you use spaces instead of tabs this will not work."
    echo ""

    if confirm "Add this line to /etc/fstab automatically?"; then
        run_cmd bash -c "echo -e '$fstab_line' | sudo tee -a /etc/fstab"
        log_info "fstab updated."
    else
        log_info "Skipped. Add the line manually with: sudo nano /etc/fstab"
    fi
    echo ""

    # Step 5: Restart
    log_info "Step 5: Restart system"
    echo "   This must be a full restart, not just EmulationStation."
    echo "   When it boots up you should see any ROMs you previously had show up in EmulationStation."
    echo ""

    if confirm "Reboot now?"; then
        run_cmd sudo reboot
    else
        log_info "Please reboot manually when ready."
    fi
}

# ── Method: Symlink ─────────────────────────────────────────────────────
method_symlink() {
    log_step "Symlink Method (itsdarklikehell)"
    echo ""
    echo "This method moves the RetroPie folder to USB and creates a symlink."
    echo ""

    detect_usb_devices

    local usb_mount
    usb_mount=$(find_usb_mount)
    if [[ -n "$usb_mount" ]]; then
        log_info "Detected USB mount point: $usb_mount"
    else
        read -r -p "Enter USB mount point [$MNTPNT]: " usb_mount
        usb_mount="${usb_mount:-$MNTPNT}"
    fi

    echo ""
    log_warn "This will:"
    echo "  1. Move $RETP_FOLDER/* to $usb_mount/"
    echo "  2. Remove the original $RETP_FOLDER directory"
    echo "  3. Create a symlink: $RETP_FOLDER -> $usb_mount"
    echo ""

    if ! confirm "Continue with symlink method?"; then
        log_info "Aborted."
        return 1
    fi

    # Step 1: Move files
    log_info "Step 1: Moving RetroPie folder to USB..."
    run_cmd sudo mv -v "$RETP_FOLDER"/* "$usb_mount/"
    log_info "Files moved."

    # Step 2: Remove original directory
    log_info "Step 2: Removing original RetroPie directory..."
    run_cmd sudo rmdir "$RETP_FOLDER" 2>/dev/null || run_cmd sudo rm -rf "$RETP_FOLDER"
    log_info "Original directory removed."

    # Step 3: Create symlink
    log_info "Step 3: Creating symlink..."
    run_cmd sudo ln -sT "$usb_mount" "$RETP_FOLDER"
    log_info "Symlink created: $RETP_FOLDER -> $usb_mount"

    # Step 4: Verify
    log_info "Step 4: Verifying..."
    if [[ -L "$RETP_FOLDER" ]]; then
        log_info "Symlink verified: $(ls -ld "$RETP_FOLDER")"
    else
        log_error "Symlink verification failed!"
        return 1
    fi

    echo ""
    log_info "Symlink method complete!"
    echo ""
    echo "Now transfer ROMs either directly to the USB drive, or via any of the usual methods."
    echo "Every time $RETP_FOLDER is accessed, you're actually accessing the USB drive."
}

# ── Usage ───────────────────────────────────────────────────────────────
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [METHOD]

Methods:
  automatic   Use RetroPie's built-in USB ROM transfer service
  manual      Configure fstab-based mounting with UUID
  symlink     Move RetroPie folder to USB and create symlink

Options:
  -d, --dry-run    Show what would be done without making changes
  -h, --help       Show this help message

Environment variables:
  RETP_FOLDER      RetroPie folder path (default: /home/pi/RetroPie)
  MNTPNT           USB mount point (default: /media/usb0)
  MOUNT_USER       User for mount ownership (default: pi)

Examples:
  $(basename "$0") automatic
  $(basename "$0") --dry-run manual
  RETP_FOLDER=/home/pi/RetroPie MNTPNT=/media/usb $(basename "$0") symlink
EOF
}

# ── Main ────────────────────────────────────────────────────────────────
main() {
    local method=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            automatic|manual|symlink)
                method="$1"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
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

    if [[ -z "$method" ]]; then
        echo "Select method:"
        echo "  1) Automatic (Easiest)"
        echo "  2) Manual (fstab)"
        echo "  3) Symlink"
        echo "  4) Exit"
        echo ""
        read -r -p "Select option [1-4]: " choice
        case "$choice" in
            1) method="automatic" ;;
            2) method="manual" ;;
            3) method="symlink" ;;
            4) exit 0 ;;
            *) log_error "Invalid option"; exit 1 ;;
        esac
    fi

    case "$method" in
        automatic) method_automatic ;;
        manual)    method_manual ;;
        symlink)   method_symlink ;;
    esac
}

main "$@"
