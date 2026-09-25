#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"
cd "$HOME/multipool/yiimp_multi" || exit 1
source system_base.sh
source db_functions.sh
source stratum_build.sh

echo -e " Building DB and stratum server...$COL_RESET"
echo
mp_mariadb_install

echo -e " Creating YiiMP DB...$COL_RESET"
mp_mariadb_create_db "$YiiMPDBName"
# The web server may only connect from its own address, the stratum runs
# on this server and connects through the local socket.
mp_mariadb_grant "$YiiMPPanelName" "$WebInternalIP" "$PanelUserDBPassword" "$YiiMPDBName"
mp_mariadb_grant "$StratumDBUser" localhost "$StratumUserDBPassword" "$YiiMPDBName"

my_cnf="$STORAGE_ROOT/yiimp/.my.cnf"
mp_new_my_cnf "$my_cnf"
mp_write_my_cnf_section "$my_cnf" clienthost1 "$YiiMPPanelName" "$PanelUserDBPassword" "$YiiMPDBName" "$WebInternalIP"
mp_write_my_cnf_section "$my_cnf" clienthost2 "$StratumDBUser" "$StratumUserDBPassword" "$YiiMPDBName" localhost
printf '[mysql]\nuser=root\npassword=%s\n' "$(mycnf_quote "$DBRootPassword")" | sudo tee -a "$my_cnf" > /dev/null
echo -e "$GREEN DB users and passwords can be found in $my_cnf$COL_RESET"

mp_import_yiimp_db
mp_mariadb_configure "$DBInternalIP"
echo -e "$GREEN Database build complete...$COL_RESET"

mp_build_stratum localhost

echo -e "$GREEN DB and stratum server build completed...$COL_RESET"
cd "$HOME/multipool/yiimp_multi" || exit 1
