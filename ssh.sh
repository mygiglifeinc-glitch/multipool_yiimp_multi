#!/usr/bin/env bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#
# Firewall for a remote server.
#   ssh.sh web|stratum|daemon
#####################################################

MP_STAGE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"
source "$MP_STAGE/system_base.sh"
source "$MP_STAGE/firewall.sh"

case "${1:-}" in
	web)
		mp_firewall_setup --public http --public https ;;
	stratum)
		# Stratum ports are opened for miners with addport or "sudo ufw allow
		# port"; the daemon server may always reach them for blocknotify.
		mp_firewall_setup --peer "${DaemonInternalIP:-}" ;;
	daemon)
		# Coin daemon RPC is only reachable from the web and stratum servers.
		mp_firewall_setup --peer "${WebInternalIP:-}" --peer "${StratumInternalIP:-}" ;;
	*)
		echo "usage: $0 web|stratum|daemon"
		exit 1 ;;
esac
exit 0
