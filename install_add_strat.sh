#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/multipool.conf
cd "$HOME/multipool/yiimp_multi" || exit 1

# Begin Installation
source questions_add_strat.sh
source add_strat_db.sh
source setsid_add_stratum_server.sh

cd ~ || exit 1
clear
echo "The new stratum server has been installed and is rebooting."
echo "On each daemon server allow RPC from it with: sudo ufw allow from ${StratumInternalIP}"
exit 0
