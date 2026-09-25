#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/multipool.conf
cd "$HOME/multipool/yiimp_multi" || exit 1

# Begin Installation
source questions_add_daemon.sh
source setsid_add_daemon_server.sh

cd ~ || exit 1
clear
echo "The new daemon server has been installed and is rebooting."
echo "Allow its IP on the stratum server(s) for blocknotify if needed: sudo ufw allow from ${DaemonInternalIP}"
exit 0
