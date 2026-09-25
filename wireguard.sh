#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#
# Sets up the WireGuard private network (wg0, UDP port 6121) between the
# pool servers, with the DB server as the hub.
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.wireguard.conf"

echo -e " Installing WireGuard...$COL_RESET"
hide_output sudo apt-get update
apt_install wireguard ufw
echo -e "$GREEN Done...$COL_RESET"

# Stop a running interface first: with SaveConfig it would otherwise write
# its old state over the new configuration.
sudo systemctl stop wg-quick@wg0 > /dev/null 2>&1 || true

# The private key is only kept in memory and in the 0600 configuration file.
sudo install -d -m 0700 /etc/wireguard
privatekey=$(umask 077 && wg genkey)
mypublic=$(printf '%s\n' "$privatekey" | wg pubkey)
printf '%s\n' "$mypublic" | sudo tee /etc/wireguard/publickey > /dev/null

wg_network="${DBInternalIP%.*}.0/24"
if [ "$server_type" = "db" ]; then
	address="${ServerInternalIP}/24"
else
	address="${ServerInternalIP}/32"
fi

{
	printf '[Interface]\nPrivateKey = %s\nListenPort = 6121\nSaveConfig = true\nAddress = %s\n' "$privatekey" "$address"
	if [ "$server_type" != "db" ]; then
		printf '\n[Peer]\nPublicKey = %s\nAllowedIPs = %s\nEndpoint = %s:6121\nPersistentKeepalive = 25\n' \
			"$DBPublicKey" "$wg_network" "$DBServerIP"
	fi
} | sudo sh -c 'umask 077; cat > /etc/wireguard/wg0.conf'
sudo chmod 0600 /etc/wireguard/wg0.conf
unset privatekey

hide_output sudo systemctl enable --now wg-quick@wg0
ufw_allow 6121/udp
clear

if [ "$server_type" = "db" ]; then
	# Public information the other servers need (no secrets).
	DBServerIP=${PUBLIC_IP}
	DBPublicKey=${mypublic}
	wireguard=true
	write_conf_file -m 644 "$STORAGE_ROOT/yiimp/.wireguard_public.conf" DBServerIP DBPublicKey wireguard

	echo Please begin the Wireguard installation on your other servers...
	echo
	echo "The public IP of this box is,  ${DBServerIP}"
	echo
	echo "The Public key of this box is, ${mypublic}"
	echo
else
	wg_command="sudo wg set wg0 peer ${mypublic} endpoint ${PUBLIC_IP}:6121 allowed-ips ${ServerInternalIP}/32"
	printf '%s\n' "$wg_command" | sudo tee "$STORAGE_ROOT/yiimp/.wireguard_command.conf" > /dev/null
	wireguard=true
	write_conf_file -m 644 "$STORAGE_ROOT/yiimp/.wireguard_public.conf" wireguard

	case "$server_type" in
		web) echo "Copy this command and run it on the DB Server, Stratum Server, and Daemon Server" ;;
		stratum) echo "Copy this command and run it on the DB Server, Web Server, and Daemon Server" ;;
		daemon) echo "Copy this command and run it on the DB Server, Web Server, and Stratum Server" ;;
		*) echo "Copy this command and run it on the DB Server, Web Server, and Daemon Server, any other additional servers" ;;
	esac
	echo
	echo "$wg_command"
	echo
	echo
fi

echo
echo "After installing Wireguard on all of your servers run, multipool from the DB server only!!"
exit 0
