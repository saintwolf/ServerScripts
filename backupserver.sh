#!/bin/bash

# So essentially this script will backup and archive the /var/www directory (www.tar.gz) and also dump the required sql databases
# into a folder with the current hostname+date+time.

# Folders to backup
www_folder="/var/www"

# Databases to backup
backup_databases="forum wikidb joomla"

# Device to mount to backup
dest_device="/dev/xvdb1"

# Where to backup to
dest="/mnt/backup"

datetime=$(date +%F-%T)
hostname=$(hostname)
backup_folder_name="$hostname-$datetime"

backup_folder_path="$dest/$backup_folder_name"

echo "Unmount backup drive if already mounted/read only"
umount $dest_device

echo "Mounting backup drive as read/write"
mount $dest_device $dest

# Check if there is a copy of the backupserver.sh in the backup storage
# and copies one there if so
if [ ! -f $dest/backupserver.sh ]; then
    cp /root/backupserver.sh $dest/backupserver.sh
fi

echo "Creating backup folder"
mkdir $backup_folder_path

echo "Backing up MariaDB databases to backup folder"
mysqldump --databases $backup_databases > $backup_folder_path/dbackup.sql

echo "Copying letsencrypt config"
cp -R /etc/letsencrypt $backup_folder_path/letsencrypt

echo "Copying apache site info and php.ini to /var/www"
mkdir -p /var/www/config/sites
cp /etc/apache2/sites-enabled/* $www_folder/config/sites
cp /etc/php/5.6/apache2/php.ini $www_folder/config/php.ini

echo "Backing up archive of /var/www/ directory"
tar czf $backup_folder_path/www.tar.gz -C $www_folder .

echo "Remount backup device as read only"
mount -o remount,ro $dest

echo "Backup complete"
