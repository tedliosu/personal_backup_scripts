#!/bin/bash

# original file location: ~/scripts/backup_os-b_mounts.sh

# Make sure we're not running as root
test "$UID" -ne "0" || exit "$(false || echo "$?")" 

# Mount points and UUIDs
readonly mount_dir="/mnt/opencl_os"
readonly root_disk_uuid="d2238766-fb74-40b1-afbf-0520ce6fcb3b"
readonly home_disk_uuid="f30ece13-22ca-4383-b119-3cd54a749bfb"
readonly efi_part_uuid="8248-8FCF"
readonly uuid_bkup_1="19d16fda-68c5-4e1d-b644-4a7dd064de31"
readonly uuid_bkup_2="f01df727-6d52-41fb-a946-c32a2455f41b"
# column number of disk label as output by lsblk
readonly disk_label_pos="2"

printf "Please enter your sudo password when prompted\n"
sudo -H true || exit "$(false || echo "$?")"
echo

# Get partition labels for each backup disk mount
readonly bkup_mount_dir_name1="$(sudo -H lsblk --output UUID,label | \
                                                 grep "$uuid_bkup_1" | tr -s " " | \
                                                 cut -d" " -f$disk_label_pos)"
readonly bkup_mount_dir_name2="$(sudo -H lsblk --output UUID,label | \
                                                 grep "$uuid_bkup_2" | tr -s " " | \
                                                 cut -d" " -f$disk_label_pos)"

if [ "$bkup_mount_dir_name1" = "" ]; then
    printf "Error - partition with UUID $uuid_bkup_1 not found\n"
    exit "$(false || echo "$?")"
fi
if [ "$bkup_mount_dir_name2" = "" ]; then
    printf "Error - partition with UUID $uuid_bkup_2 not found\n"
    exit "$(false || echo "$?")"
fi

# mount all built-in physical disks
sudo -H mount --uuid "$root_disk_uuid" "$mount_dir"
sudo -H mount --uuid "$efi_part_uuid" "$mount_dir/boot/efi"
sudo -H mount --uuid "$home_disk_uuid" "$mount_dir/home"
# create new mountpoints under directory to chroot to if necessary
if [ ! -d "$mount_dir/media/root/$bkup_mount_dir_name1" ]; then
   sudo -H mkdir "$mount_dir/media/root/$bkup_mount_dir_name1"
fi
if [ ! -d "$mount_dir/media/root/$bkup_mount_dir_name2" ]; then
   sudo -H mkdir "$mount_dir/media/root/$bkup_mount_dir_name2"
fi
# mount rest of physical disks
sudo -H mount --uuid "$uuid_bkup_1" "$mount_dir/media/root/$bkup_mount_dir_name1"
sudo -H mount --uuid "$uuid_bkup_2" "$mount_dir/media/root/$bkup_mount_dir_name2"

# bind mounts for chroot
sudo -H mount --bind /tmp "$mount_dir/tmp"
sudo -H mount --bind /run "$mount_dir/run"
sudo -H mount --bind /dev "$mount_dir/dev"
sudo -H mount --bind /dev/pts "$mount_dir/dev/pts"
sudo -H mount --bind /sys "$mount_dir/sys"
sudo -H mount --bind /proc "$mount_dir/proc"

sudo -H chroot "$mount_dir" /bin/bash

sudo -H true || exit "$(false || echo "$?")"
echo

# cleanup unmounts
sudo -H umount "$mount_dir/proc"
sudo -H umount "$mount_dir/sys"
sudo -H umount "$mount_dir/dev/pts"
sudo -H umount "$mount_dir/run"
sudo -H umount "$mount_dir/tmp"
sudo -H umount "/dev/disk/by-uuid/$efi_part_uuid"
sudo -H umount "/dev/disk/by-uuid/$home_disk_uuid"
sudo -H umount "/dev/disk/by-uuid/$uuid_bkup_1"
sudo -H umount "/dev/disk/by-uuid/$uuid_bkup_2"
# Lazy unmount dev and root directory AFTER umounting all other physical devices
sudo -H umount --lazy "$mount_dir/dev"
sudo -H umount --lazy "$mount_dir"

echo "Success in chroot!"

