#!/usr/bin/env bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#
# Firewall for the DB (or DB + stratum) server: MariaDB is only reachable
# from the web and stratum servers.
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"
cd "$HOME/multipool/yiimp_multi" || exit 1
source system_base.sh
source firewall.sh

if [ -n "${StratumInternalIP:-}" ] && [ "$StratumInternalIP" != "$DBInternalIP" ]; then
	# DB server with a separate stratum server
	mp_firewall_setup --peer-port "$WebInternalIP" 3306/tcp --peer-port "$StratumInternalIP" 3306/tcp
else
	# DB + stratum server: the daemon server sends blocknotify to the stratums.
	mp_firewall_setup --peer-port "$WebInternalIP" 3306/tcp --peer "${DaemonInternalIP:-}"
fi
cd "$HOME/multipool/yiimp_multi" || exit 1
