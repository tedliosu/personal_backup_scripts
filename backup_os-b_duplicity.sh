#!/bin/bash

# This script file location: /root/scripts/backup_os-b_duplicity.sh

# exit if not running as root
if [ "$UID" -ne "0" ]; then
   printf "Please run script as root\n"
   exit "$(false || echo "$?")" 
fi

# Volume size of each resulting backup archive using duplicity
readonly volume_size="500"
# Min number of files in the directory NOT to backup to
readonly min_file_count="2"
## UUIDS of backup disks
readonly uuid_bkup_1="19d16fda-68c5-4e1d-b644-4a7dd064de31"
readonly uuid_bkup_2="f01df727-6d52-41fb-a946-c32a2455f41b"
# column number of disk label as output by lsblk
readonly disk_label_pos="2"
# find command min search depth
readonly find_min_search_depth=1

# Get mounts of current disks
readonly bkup_mount_dir1="$(lsblk --output UUID,mountpoint | \
                                    grep "$uuid_bkup_1" | tr -s " " | \
				    cut -d " " -f$disk_label_pos)"
readonly bkup_mount_dir2="$(lsblk --output UUID,mountpoint | \
                                    grep "$uuid_bkup_2" | tr -s " " | \
				    cut -d " " -f$disk_label_pos)"

if [ "$bkup_mount_dir1" = "" ]; then
      printf "Error - partition with UUID %s not found\n" "$uuid_bkup_1"
      exit "$(false || echo "$?")"
fi
if [ "$bkup_mount_dir2" = "" ]; then
      printf "Error - partition with UUID %s not found\n" "$uuid_bkup_2"
      exit "$(false || echo "$?")"
fi

# Determine which directory to backup to and which to clear via file count
curr_bkup_dir=""
old_bkup_dir=""
readonly bkup_mount_dir1_count="$(find "$bkup_mount_dir1" -mindepth "$find_min_search_depth" -maxdepth "$find_min_search_depth" | wc --lines)"
readonly bkup_mount_dir2_count="$(find "$bkup_mount_dir2" -mindepth "$find_min_search_depth" -maxdepth "$find_min_search_depth" | wc --lines)"
if [ "$bkup_mount_dir1_count" -le "$min_file_count" ]; then
	curr_bkup_dir="$bkup_mount_dir2/$(find "$bkup_mount_dir2" -mindepth "$find_min_search_depth" -maxdepth "$find_min_search_depth" -print0 | xargs --null --max-lines=1 basename | grep "^\." )/"
	old_bkup_dir="$bkup_mount_dir1/$(find "$bkup_mount_dir1" -mindepth "$find_min_search_depth" -maxdepth "$find_min_search_depth" -print0 | xargs --null --max-lines=1 basename | grep "^\." )/"
elif [ "$bkup_mount_dir2_count" -le "$min_file_count" ]; then
	curr_bkup_dir="$bkup_mount_dir1/$(find "$bkup_mount_dir1" -mindepth "$find_min_search_depth" -maxdepth "$find_min_search_depth" -print0 | xargs --null --max-lines=1 basename | grep "^\." )/"
	old_bkup_dir="$bkup_mount_dir2/$(find "$bkup_mount_dir2" -mindepth "$find_min_search_depth" -maxdepth "$find_min_search_depth" -print0 | xargs --null --max-lines=1 basename | grep "^\." )/"
else
	printf "ERROR - cannot determine which directory to backup to based on file counts.\n"
	exit "$(false || echo "$?")" 
fi
curr_bkup_dir_url="file://$curr_bkup_dir"

set -x
# Now do actual backup
duplicity --volsize "$volume_size" --exclude /dev --exclude /proc --exclude /tmp --exclude /sys --exclude /media --exclude /mnt --exclude /run / "$curr_bkup_dir_url"
duplicity_exit_code="$?"
set +x

# Now proceed ONLY IF backup was successful
if [ "$duplicity_exit_code" -eq "0" ]; then
     printf "Setting immutability attribute on new backup\n"
     chattr -R +i "${curr_bkup_dir}"
     printf "Remove immutability attribute on old backup and delete old backup\n"
     chattr -R -i "${old_bkup_dir}"
     rm -r "${old_bkup_dir}"
fi

