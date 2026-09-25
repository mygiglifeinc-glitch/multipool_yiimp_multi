#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"
source "$STORAGE_ROOT/yiimp/.newconf.conf"
cd "$HOME/multipool/yiimp_multi" || exit 1
source system_base.sh
source db_functions.sh

echo -e " Creating new stratum user for YiiMP...$COL_RESET"
mp_mariadb_grant "$StratumDBUser" "$StratumInternalIP" "$StratumUserDBPassword" "$YiiMPDBName"

generate=$(generate_password 12)
my_cnf="$STORAGE_ROOT/yiimp/.my.${generate}.cnf"
echo "Creating $my_cnf..."
mp_new_my_cnf "$my_cnf"
mp_write_my_cnf_section "$my_cnf" clienthost1 "$StratumDBUser" "$StratumUserDBPassword" "$YiiMPDBName" "$StratumInternalIP"

# Let the new stratum server reach MariaDB.
if [ -z "${DISABLE_FIREWALL:-}" ]; then
	ufw_allow from "$StratumInternalIP" to any port 3306 proto tcp
fi

echo -e "$GREEN DB user and password can be found in $my_cnf$COL_RESET"
echo
echo -e "$GREEN New user created...$COL_RESET"
cd "$HOME/multipool/yiimp_multi" || exit 1
