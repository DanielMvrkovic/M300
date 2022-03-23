#!/bin/bash

backup_files="/mnt/nfs-share/logs/apache/access.log /mnt/nfs-share/logs/apache/error.log /mnt/nfs-share/logs/apache/other_vhosts_access.log"

dest="/backup/log_bk"

day=$(date +%A)
filename="apache_log"
archive_file="$filename-$day.tgz"

tar czf /backup/log_bk/apache.log.bk.tgz /mnt/nfs-share/logs/apache/access.log /mnt/nfs-share/logs/apache/error.log /mnt/nfs-share/logs/apache/other_vhosts_access.log
