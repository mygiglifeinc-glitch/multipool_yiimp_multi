#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#
# Needs to be ran after the first reboot of the system after permissions are set
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
sleep 5
yiimp checkup > /dev/null 2>&1 || true

# Prevents error when trying to log in to admin panel the first time...
# The log directory is shared by the cron screens (this user) and php-fpm
# (www-data) through the www-data group ACL set by the installer.
sudo touch "$STORAGE_ROOT/yiimp/site/log/debug.log"
sudo chgrp www-data "$STORAGE_ROOT/yiimp/site/log/debug.log"
sudo chmod 0664 "$STORAGE_ROOT/yiimp/site/log/debug.log"

# Delete me no longer needed after it runs the first time
sudo rm -f "$STORAGE_ROOT/yiimp/first_boot.sh"
