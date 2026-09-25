#!/usr/bin/env bash
#####################################################
# Source code https://github.com/end222/pacmenu
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
cd "$HOME/multipool/yiimp_multi" || exit 1
source questions_common.sh

function is_valid_wg_key {
	[[ "$1" =~ ^[A-Za-z0-9+/]{42}[AEIMQUYcgkosw048]=$ ]]
}

# Ask for the DB server public IP and WireGuard public key.
function ask_db_peer {
	while ! is_valid_ipv4 "${DBServerIP:-}"; do
		read -r -e -p "Please enter the DB servers PUBLIC IP : " DBServerIP
	done
	while ! is_valid_wg_key "${DBPublicKey:-}"; do
		read -r -e -p "Please enter the DB public key that was displayed : " DBPublicKey
	done
}

RESULT=$(dialog --stdout --title "Ultimate Crypto-Server Setup Installer" --menu "Choose one" -1 60 6 \
	1 "Install Wireguard on DB Server or DB-Stratum Server" \
	2 "Install Wireguard on Web Server" \
	3 "Install Wireguard on First Stratum Server Only" \
	4 "Install Wireguard on Daemon Server" \
	5 "Install Wireguard on Additional Server(s)" \
	6 Exit)

DBInternalIP='10.0.0.2'
sudo mkdir -p "$STORAGE_ROOT/yiimp"
case "$RESULT" in
	1)
		clear
		server_type=db
		ServerInternalIP=$DBInternalIP
		;;
	2)
		clear
		ask_db_peer
		server_type=web
		ServerInternalIP='10.0.0.3'
		;;
	3)
		clear
		ask_db_peer
		server_type=stratum
		ServerInternalIP='10.0.0.4'
		;;
	4)
		clear
		ask_db_peer
		server_type=daemon
		ServerInternalIP='10.0.0.5'
		;;
	5)
		clear
		source wire_warning.sh

		if [ -z "${AdditionalInternalIP:-}" ]; then
			ask_input "Additional Server Private IP" \
				"Enter the new Private IP of this server.
\n\nMake sure not to reuse an IP already in use!
\n\nPrivate IP address:" \
				10.0.0.x AdditionalInternalIP is_valid_ipv4
		fi

		if [ -z "${DBServerIP:-}" ]; then
			ask_input "DB Server Public IP" \
				"Enter the Public IP of your DB Server.
\n\nDB Public IP address:" \
				x.x.x.x DBServerIP is_valid_ipv4
		fi

		if [ -z "${DBPublicKey:-}" ]; then
			ask_input "DB Server Public Key" \
				"Enter the Public Key of your DB Server.
\n\nDB Public Key:" \
				PublicKey DBPublicKey is_valid_wg_key
		fi
		server_type=additional
		ServerInternalIP=$AdditionalInternalIP
		;;
	*)
		clear
		exit
		;;
esac

write_conf_file -m 600 "$STORAGE_ROOT/yiimp/.wireguard.conf" \
	server_type ServerInternalIP DBInternalIP DBServerIP DBPublicKey
cd "$HOME/multipool/yiimp_multi" || exit 1
source wireguard.sh
exit
