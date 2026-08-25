#!/bin/bash
echo 'format USB drive.'
echo ''
echo ' BE EXTREMELY CAREFULL! '
echo 'i am in no way to be held responsible for loss of data, revenue or any damage done to your system by YOU running this script WITHOUT READING IT FIRST!'
read -rsp $'Press any key to continue...\n' -n 1
# echo $key
clear
FINDMNT(){
echo 'To find out the USB device mount point, utilize the `fdisk` command.'
read -rsp $'Press any key to continue...\n' -n 1
# echo $key
echo 'On my system, the last line in the above listing - `/dev/sdb1` is the USB mount point.'
echo 'MAKE SURE ITS THE RIGHT ONE, OR ELSE FACE THE CONSEQUENCES OF LOSING ALL DATA ON THAT DRIVE/PARTITON'
fdisk -l
echo 'write it down..'
read -rsp $'Press any key to continue...\n' -n 1
# echo $key
}
FINDMNT

FAT32(){
echo 'To format a USB storage device with FAT32 file system, use the below command.'
echo 'mkfs -t vfat <USB-device-mount-point>'
}

EXT2(){
echo 'Extended2 File System:'
echo 'mkfs.ext2 <USB-device-mount-point>'
}

EXT39(){
echo 'Extended3 File System:'
echo 'mkfs.ext3 <USB-device-mount-point>'
}

EXT4(){
echo 'Extended4 file system (if you have the latest version of any Linux OS, ext4 should be supported):'
echo 'mkfs.ext4 <USB-device-mount-point>'
}

JOURNAL(){
echo 'Journal File System:'
echo 'mkfs.jfs <USB-device-mount-point>'
}

NTFS(){
echo 'NTFS File System:'
echo 'mkfs.ntfs <USB-device-mount-point>'
}

XFS(){
echo 'XFS'
echo 'mkfs.xfs <USB-device-mount-point>'
}

REISERFS(){
echo 'ReiserFS'
echo 'mkfs.reiserfs <USB-device-mount-point>'
}
