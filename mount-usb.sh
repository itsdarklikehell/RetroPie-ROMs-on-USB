#!/bin/bash
set -euo pipefail

# mount-usb.sh - Mount a USB drive for RetroPie ROMs
# Usage: ./mount-usb.sh [method]
# Methods: automatic, manual, symlink
# Example: ./mount-usb.sh symlink

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME

# Colors for output
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m' # No Color

log_info()  { echo -e "${YELLOW}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

cleanup() {
    stty echo 2>/dev/null || true
}
trap cleanup EXIT INT TERM

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [METHOD]

Mount a USB drive for RetroPie ROMs.

Methods:
  automatic   Use RetroPie's built-in USB ROM transfer service
  manual      Manual mount via fstab configuration
  symlink     Create a symlink from RetroPie folder to USB

Examples:
  ${SCRIPT_NAME} symlink
  ${SCRIPT_NAME} manual

WARNING: The symlink and manual methods involve moving data.
         Ensure you have backups before proceeding.
EOF
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)."
        exit 1
    fi
}

get_retropie_folder() {
    echo "/home/pi/RetroPie"
}

get_mount_point() {
    echo "/media/usb0"
}

method_automatic() {
    log_info "Automatic Mount (Easiest Method)"
    echo
    echo "1. First Update the RetroPie Setup Script"
    echo "2. Re-Enable the USB ROM Transfer Service"
    echo "3. Format your USB drive to FAT32 (format-usb.sh)"
    echo "4. Create a folder called retropie-mount on the USB drive"
    echo "5. Plug into Raspberry Pi (if not already)"
    echo "It will proceed to automatically copy the RetroPie folder AND all of its contents (you may need to reboot to start the copying)"
    echo
    echo "NOTE: If you have a large ROM collection already on the SD card it will copy all of the ROMs too so make sure your USB is large enough."
    echo "It is easiest if you haven't added any ROMs yet."
    echo
    echo "Once the folder structure is copied over the USB will be mounted over the RetroPie folder so any ROMs you add to your pi will be run off of the USB."
    echo
    read -rsp "Press any key to continue..." -n 1
    echo
    log_ok "Automatic method instructions complete"
}

method_manual() {
    local retp_folder
    local mnt_pnt
    retp_folder=$(get_retropie_folder)
    mnt_pnt=$(get_mount_point)

    log_info "Manual Mount"
    echo "After formatting your USB (format-usb.sh):"
    echo
    echo "1. Disable USB transfer daemon:"
    echo "   Enter the RetroPie Setup menu within the RetroPie menu in EmulationStation."
    echo "   Select Setup / Tools."
    echo "   Select usbromservice - USB ROM Service"
    echo "   Disable USB ROM Service."
    echo "2. Plug in USB drive"
    echo "   This can be done when the system is powered on."
    echo
    echo "Transfer the existing RetroPie file structure"
    echo "This step is mandatory regardless of whether you have any ROMs on your system."
    echo
    read -rsp "Press any key to continue..." -n 1
    echo
    echo "Either via SFTP, or using the terminal (via exiting emulationstation, pressing F4, or remotely using SSH), move the $retp_folder folder into your USB stick."
    echo "The reason for moving the whole folder, and not just $retp_folder/roms is that there are other folders, such as $retp_folder/BIOS that are worth keeping on the external drive also."
    echo
    echo "To do this via terminal, first enter the command df to print a list of the file systems."
    echo
    df
    echo
    echo "Look for an entry on $mnt_pnt, or similar."
    echo
    echo "The important things to note down are the mount point: $mnt_pnt, and the position on the device tree: /dev/sda1"
    echo
    read -rsp "Press any key to continue..." -n 1
    echo
    echo "Now we can move our existing RetroPie folder to our new USB drive."
    echo "sudo mv -v $retp_folder/* $mnt_pnt"
    echo
    echo "Configure fstab to automatically mount USB drive"
    echo
    echo "Establish the drive's UUID number by entering the command: ls -l /dev/disk/by-uuid/"
    echo
    read -rsp "Press any key to continue..." -n 1
    echo
    echo "Edit fstab with this command: sudo nano /etc/fstab and add a new line like the below:"
    echo "UUID=<your-uuid>	$retp_folder	vfat	nofail,user,uid=pi,gid=pi	0	2"
    echo "...where UUID= the UUID of your drive, and everything else is the same as the example. Note that each item is tab delimited. If you use spaces instead of tabs this will not work."
    echo
    echo "In the case of errors with ext4 file systems use:"
    echo 'UUID="<your-uuid>" '"$retp_folder"' ext4 nofail,defaults 0    0'
    echo
    echo "In the case you want to allow execution of file with fat32 file system (e.g., OpenBOR), use:"
    echo "UUID=<your-uuid>	$retp_folder	vfat	rw,exec,uid=pi,gid=pi,umask=022	0	2"
    echo
    read -rsp "Press any key to continue..." -n 1
    echo
    echo "Restart system"
    echo "This must be a full restart, not just emulationstation. When it boots up you should see any ROMs you previously had show up in emulationstation."
    echo
    read -rsp "Press any key to continue..." -n 1
    echo
    echo "Transfer ROMs"
    echo "Now transfer ROMs either directly to the USB drive, or via any of the usual methods (aside from using the automatic USB copy, obviously!)."
    echo "Now that the USB drive is mounted directly to $retp_folder, every time this directory is accessed, you're actually accessing the USB drive."
    echo
    log_ok "Manual method instructions complete"
}

method_symlink() {
    local retp_folder
    local mnt_pnt
    retp_folder=$(get_retropie_folder)
    mnt_pnt=$(get_mount_point)

    log_info "Symlink Method"
    echo
    echo "Transfer the existing RetroPie file structure"
    echo
    echo "This step is mandatory regardless of whether you have any ROMs on your system. RetroPie has a specific directory structure and a number of files required packaged with even empty installations."
    echo
    echo "First enter the command df to print a list of the file systems."
    echo
    df
    echo
    read -rsp "Press any key to continue..." -n 1
    echo
    echo "Moving $retp_folder to $mnt_pnt..."
    sudo mv -v "$retp_folder"/* "$mnt_pnt"
    ls -l "$mnt_pnt"
    echo
    read -rsp "Press any key to continue..." -n 1
    echo
    echo "Creating symlink from $retp_folder to $mnt_pnt..."
    ln -sT "$mnt_pnt" "$retp_folder"
    echo
    echo "Checking if symlink is working:"
    ls -l "$retp_folder"
    echo
    log_ok "Symlink method complete"
}

main() {
    local method="${1:-}"

    check_root

    if [[ -z "$method" ]]; then
        echo "Select mount method:"
        echo "  1) automatic  (RetroPie USB ROM transfer service)"
        echo "  2) manual     (fstab configuration)"
        echo "  3) symlink    (symlink RetroPie folder to USB)"
        echo
        read -rp "Enter choice [1-3]: " choice
        case "$choice" in
            1) method="automatic" ;;
            2) method="manual" ;;
            3) method="symlink" ;;
            *) log_error "Invalid choice: $choice"; exit 1 ;;
        esac
    fi

    case "$method" in
        automatic) method_automatic ;;
        manual)    method_manual ;;
        symlink)   method_symlink ;;
        *)         log_error "Unknown method: $method"; usage; exit 1 ;;
    esac
}

main "$@"
