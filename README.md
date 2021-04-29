# These four scripts assume the following -

  - There are two different Linux distros, Operating System (OS) A and OS B, installed on one machine.
      One may log into OS A and easily chroot into OS B and vice versa as necessary.

  - The script files whose file name contain "os-a" gets placed inside the appropriate directory (see comment
      denoting original location of script within each file for more info) in OS A and vice versa.

  - The external media being backed up to has two different ext4 partitions, where one partition ONLY
      contains the "lost+found" folder, and the other partition contains the backed-up files of OS A under the
      partition's root directory and the backed-up files of OS B within a hidden directory under the root
      directory, and that there are NO OTHER HIDDEN DIRECTORIES under the other partition's root directory.
      Essentially, this means that all the backed-up files for one machine reside within one partition and
      one partition ONLY.


# Procedure for using these scripts

  1. Modify the UUIDs listed on the top of each script for YOUR use case AFTER putting each script
      in the appropriate directory (again, refer to the "Original location" of the script for more info).

  2. Plug-in the external media containing the existing backups into the computer. If both of the external media's
      two ext4 partitions each do not contain anything else other than the "lost+found" directory, simply pick one
      of the partitions and create an empty hidden directory directly under the root folder of that partition 

  3. Log into OS B and run "backup_os-a_mounts.sh" in order to chroot into OS A and mount all necessary devices
      and bind mounts
 
  4. Once chrooted into OS A, run "backup_os-a_duplicity.sh"

  5. Once the duplicity command has finished backing up files and the (CLI) prompt is brought back up again, exit
      the chroot and reboot into OS A.

  6. Now run "backup_os-b_mounts.sh" in order to chroot into OS B and mount all necessary devices and bind mounts

  7. Once chrooted into OS B, run "backup_os-b_duplicity.sh"

  8. Once the duplicity command has finished backing up files and the (CLI) prompt is brought back up again, exit
      the chroot and power off the external media in which the backups for both OS A and OS B are stored.

  9. Congratulations, you've just performed system backups for both Linux distros on your machine! :)


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

