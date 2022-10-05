# These four scripts assume the following -

  - There are two different Linux distros, Operating System (OS) A and OS B, installed on the same machine.
      One may log into OS A and easily chroot into OS B and vice versa as necessary.

  - The script files whose file name contain "os-a" gets placed inside the appropriate directory (see comment
      denoting original location of script within each file for more info) in OS A and vice versa.

  - The external media being backed up to has two different **ext4** partitions (here we'll refer to them as
    partitions A and B).
    
       - Each partition's file system should have a file system label; if that's not the case, you'll
         get to make these labels in the procedure as described below under "**Procedure for using these scripts**".

  - What ext4 partitions A and B on the external media each contains:

       - IF the external media already contains backups for both OS's, then partition A (or vice versa B) ONLY
         contains the "lost+found" folder, whereas partition B (or vice versa A) contains the backed-up files
         of OS A under partition B's (or vice versa A's) root directory and the backed-up files of OS B within
         a hidden directory under the root directory.  There should also be NO OTHER HIDDEN DIRECTORIES under
         the partition B's (or vice versa A's) root directory. Essentially, this means that all the backed-up
         files for one machine reside within one partition and one partition ONLY.

       - Otherwise, it is assumed that each partition is a clean **ext4** partition with only a "lost+found"
         folder and there are NO OTHER FILES on the partition.


# Procedure for using these scripts

  1. Modify the UUIDs listed on the top of each script for YOUR use case AFTER putting each script
      in the appropriate directory (again, refer to the "original location" at the top of each script
      within each script for more info).

      1. For the scripts whose file names contain "**os-a**", the "root_disk_uuid", "home_disk_uuid"
         (if applicable to YOUR machine), and "efi_part_uuid" variable values each must match the UUID
         of the disk partition containing the `/` directory, the UUID of the disk partition containing
         the `/home` directory, and the UUID of the disk partition containing the `/boot/efi` directory
         respectively **of OS B**.  The vice versa applies for the scripts whose file names contain
         "**os-b**" (i.e. having the variable values match UUIDs of disk partitions **of OS A**).

      2. DISABLE all auto-mounting of external media on your machine for each OS, and plug in the
         external media (the same media as mentioned above under "**These four scripts assume the following - **")
         into the computer.  Then make sure that for each script, the value of "uuid_bkup_1" is set
         to partition A's UUID and the value of "uuid_bkup_2" is set to partition B's UUID.
    
      3. On the external media, label partition A's file system and partition B's file system, preferably
         labeling each file system with meaningful names like "backup-my-linux-1" for partition A's file
         system label and "backup-my-linux-2" for partition B's file system label.
            
          - Each of the labels can be changed later if desired without affecting how each script runs as long
            as each script isn't running while the label is being changed.
      
  2.  If both of the external media's partitions' file systems each do not contain anything else other than
      the "lost+found" directory, simply pick one of the partitions, mount that partition, and create an empty
      hidden directory directly under the root folder of that partition, preferably naming that hidden directory
      with a name which reflects its purpose like ".os_b_backups". Also create an empty regular file named "duplicity_empty"
      within that same directory that you have created the hidden directory. Unmount the partition after you're done
      creating the hidden directory and "duplicity_empty". 

         - The name of the hidden directory can be changed later if desired without affecting how each script
           runs as long as each script isn't running while the directory name is being changed.
            
         - The empty regular file will be deleted when the backup script under `/root/scripts` successfully finishes executing.

         - If the external media already contain backups for both OS's, then you may skip to the next step.

  3. Log into OS B and run "backup_os-a_mounts.sh" in order to chroot into OS A and mount all necessary devices
      and bind mounts
 
  4. Once chrooted into OS A, run "backup_os-a_duplicity.sh"

  5. Once the duplicity command has finished backing up files and the (CLI) prompt is brought back up again, exit
      the chroot and reboot into OS A.

  6. Now run "backup_os-b_mounts.sh" in order to chroot into OS B and mount all necessary devices and bind mounts

  7. Once chrooted into OS B, run "backup_os-b_duplicity.sh"

  8. Once the duplicity command has finished backing up files and the (CLI) prompt is brought back up again, exit
      the chroot and power off the external media in which the backups for both OS A and OS B are now stored.

  9. Congratulations, you've just performed system backups for both Linux distros on your machine! :) For any future
     backups, simply make sure that auto-mounting of all external media is disabled, plug in the same external media
     which you've used previously to backup OS A and OS B, and then repeat steps 3 - 8 in this procedure.


# But why is my backup procedure so complicated?

  - I've tried chrooting from a bootable USB to do backups, but unfortunately since a USB thumb-drive's random
      read-write performance is terrible I find myself spending time waiting for the OS to finish loading. And since
      I had a spare SSD (at least for my laptop) I though I might as well put it to good use.

  - I have also tried doing incremental backups instead of doing a full backup every time, but I've found that the
      external media I use to back things up is so slow that an incremental backup ends up taking about the same
      amount of time compared to just doing a full back-up instead.  In addition I've found that incremental backups
      are not as storage-space-efficient as just doing a full-backup every-time from scratch via switching between
      which partition I back up to every time I back up my OS's.

  - While backing up to the cloud might be better for ensuring data integrity, I have found that even with a
      fast internet connection the upload speed is extremely slow as compared to backing up to just my own personal
      external media (A seagate hard drive), and doing a complete restore from the cloud (which I have done in the
      past) takes up a LOT of my time because of how slow an internet connection (e.g. 15 MiB/s) is generally
      compared to personal external media (80 MiB/s).

  - If I try backing up an OS while it's running, I've discovered that I end up corrupting the video driver's files
      since unless if the OS is actually NOT RUNNING during the backup, the backup doesn't properly save those video
      driver files.  And so in the event I do need to perform a restore, I end up having to chroot into the restored
      OS's root directory anyway just so I can purge and reinstall the video drivers.

