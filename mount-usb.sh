#!/bin/bash
DISCLAIMER(){
# DISCLAIMER START
echo ' BE EXTREMELY CAREFULL! '
echo 'i am in no way to be held responsible for loss of data, revenue or any damage done to your system by YOU running this script WITHOUT READING IT FIRST!'
read -rsp $'Press any key to continue...\n' -n 1 key
# echo $key
clear
}
DISCLAIMER
CONFIG(){
# CONFIG START
echo 'Start configuring'
RETP_FOLDER=/home/pi/RetroPie
MNTPNT=/dev/sda1 #/media/usb0
}
AUTOMATIC(){
# Automatic Mount
echo 'Automatic Mount (Easiest Method)'
echo 'As of December 30, 2016 a simple automated method was added to run roms from a USB drive.'
echo ''
echo '1. First Update the RetroPie Setup Script'
echo '2. Re-Enable the USB ROM Transfer Service'
echo '3. Format your USB drive to FAT32 (format-ubs.sh)'
echo '4. Create a folder called retropie-mount on the USB drive'
sudo mkdir $MNTPNT/retropie-mount
echo '5. Plug into Raspberry Pi (if not allready)'
echo 'It will proceed to automatically copy the RetroPie folder AND all of its contents (you may need to reboot to start the copying)'
echo 'NOTE if you have a large ROM collection already on the SD card it will copy all of the ROMs too so make sure your USB is large enough.'
echo 'It is easiest if you haven`t added any roms yet.'
echo ''
echo 'Once the folder structure is copied over the USB will be mounted over the RetroPie folder so any ROMs you add to your pi will be run off of the USB.'
read -rsp $'Press any key to continue...\n' -n 1 key
# echo $key
clear
echo 'automatic method done'
read -rsp $'Press any key to continue...\n' -n 1 key
# echo $key
clear
}
MANUAL(){
# Manual Mount
echo 'Manual Mount'
echo 'After formatting your USB (format-usb.sh):'
echo ''
echo '1. Disable USB transfer daemon:'
echo '   Enter the RetroPie Setup menu within the RetroPie menu in EmulationStation.'
echo '   Select Setup / Tools.'
echo '   Select usbromservice - USB ROM Service'
echo '   Disable USB ROM Service.'
echo '2. Plug in USB drive'
echo '   This can be done when the system is powered on.'
echo ''
echo 'Transfer the existing RetroPie file structure'
echo 'This step is mandatory regardless of whether you have any roms on your system. RetroPie has a specific directory structure and a number of files required packaged with even empty installations.'
echo ''
echo 'Either via SFTP, or using the terminal (via exiting emulationstation, pressing F4, or remotely using [[SSH]]), move the $RETP_FOLDER folder into your USB stick. The reason for moving the whole folder, and not just $RETP_FOLDER/roms is that there are other folders, such as $RETP_FOLDER/BIOS` that are worth keeping on the external drive also.'
echo ''
echo 'To do this via terminal, First enter the command df to print a list of the file systems.'
echo ''
df
echo ''
echo 'Look for an entry on $MNTPNT, or similar.'
echo ''
echo 'The important things to note down are the mount point: $MNTPNT, and the position on the device tree: /dev/sda1'
read -rsp $'Press any key to continue...\n' -n 1 key
# echo $key
echo ''
echo 'Now we can move our existing RetroPie folder to our new USB drive.'
echo 'sudo mv -v $RETP_FOLDER/* $MNTPNT'
#sudo mv -v $RETP_FOLDER/* $MNTPNT
echo ''
echo 'Configure fstab to automatically mount USB drive'
echo ''
echo 'Establish the drive`s UUID number by entering the command ls -l /dev/disk/by-uuid/.'
echo ''
read -rsp $'Press any key to continue...\n' -n 1 key
# echo $key
echo 'Edit fstab with this command: sudo nano /etc/fstab and add a new line like the below:'
echo 'UUID=XXXX-XXXX  $RETP_FOLDER      vfat    nofail,user,uid=pi,gid=pi 0       2'
echo '...where UUID= the UUID of your drive, and everything else is the same as the example. Note that each item is tab delimited. If you use spaces instead of tabs this will not work.'
echo ''
read -rsp $'Press any key to continue...\n' -n 1 key
# echo $k
echo 'In the case of errors with ext4 file systems use:'
echo 'UUID="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXX" $RETP_FOLDER ext4 nofail,defaults 0    0'
echo ''
read -rsp $'Press any key to continue...\n' -n 1 key
# echo $key
echo 'In the case you want to allow execution of file with fat32 file system (E.g : OpenBOR), use:'
echo 'UUID=E44B-FC4E  $RETP_FOLDER      vfat    rw,exec,uid=pi,gid=pi,umask=022 0       2'
echo ''
read -rsp $'Press any key to continue...\n' -n 1 key
# echo $key
echo 'Restart system'
echo ''
echo 'This must be a full restart, not just emulationstation. When it boots up you should see any ROMs you previously had show up in emulationstation.'
echo ''
read -rsp $'Press any key to continue...\n' -n 1 key
# echo $key
clear
#sudo reboot
echo 'Transfer ROMs'
echo 'Now transfer ROMs either directly to the USB drive, or via any of the usual methods (aside from using the automatic USB copy, obviously!).'
echo 'Now that the USB drive is mounted directly to home/pi/RetroPie, every time this directory is accessed, you`re actually accessing the USB drive.'
read -rsp $'Press any key to continue...\n' -n 1 key
# echo $key
clear
echo 'manual method done'
read -rsp $'Press any key to continue...\n' -n 1 key
# echo $key
clear
}
SYMLINKED(){
# itsdarklikehell`s symlink method:
echo 'itsdarklikehell`s symlink method:'
echo ''
echo 'Transfer the existing RetroPie file structure'
echo ''
echo 'This step is mandatory regardless of whether you have any roms on your system. RetroPie has a specific directory structure and a number of files required packaged with even empty installations.'
echo ''
echo 'First enter the command df to print a list of the file systems.'
echo ''
df

echo 'sudo mv -v $RETP_FOLDER/* $MNTPNT'
#sudo mv -v $RETP_FOLDER/* $MNTPNT
ls -l $MNTPNT
read -rsp $'Press any key to continue...\n' -n 1 key
# echo $key
echo 'make symlinks' 
#ln $RETP_FOLDER $MNTPNT
read -rsp $'Press any key to continue...\n' -n 1 key
# echo $key
echo 'check if symlink is working'
ls -l $RETP_FOLDER
read -rsp $'Press any key to continue...\n' -n 1 key
# echo $key
clear
echo 'symlink mehod done'
read -rsp $'Press any key to continue...\n' -n 1 key
# echo $key
clear
}

################
CONFIG
#AUTOMATIC
#MANUAL
SYMLINKED