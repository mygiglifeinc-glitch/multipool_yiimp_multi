#!/usr/bin/env bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#
# Defines mp_firewall_setup. Everything is denied except SSH, what the server
# role needs publicly, and traffic from the other servers of the pool.
#####################################################

# mp_firewall_setup [--public PORT/PROTO]... [--peer IP]... [--peer-port IP PORT/PROTO]...
#   --public     allow from anywhere
#   --peer       allow everything from that (private) address
#   --peer-port  allow only that port from that address
function mp_firewall_setup {
	local port
	if [ -n "${DISABLE_FIREWALL:-}" ]; then
		return 0
	fi
	echo -e " Initializing UFW Firewall...$COL_RESET"
	apt_install ufw
	sudo ufw default deny incoming > /dev/null
	sudo ufw default allow outgoing > /dev/null

	# Allow incoming connections to SSH, on whatever port sshd uses.
	for port in $(mp_ssh_ports); do
		ufw_allow "${port}/tcp"
	done
	if [[ "${wireguard:-false}" == "true" ]]; then
		ufw_allow 6121/udp
	fi

	while [ $# -gt 0 ]; do
		case "$1" in
			--public)
				ufw_allow "$2"
				shift 2 ;;
			--peer)
				if [ -n "$2" ]; then ufw_allow from "$2"; fi
				shift 2 ;;
			--peer-port)
				if [ -n "$2" ]; then ufw_allow from "$2" to any port "${3%/*}" proto "${3#*/}"; fi
				shift 3 ;;
			*)
				echo "mp_firewall_setup: unknown option $1" >&2
				return 1 ;;
		esac
	done

	sudo ufw --force enable > /dev/null
	echo -e "$GREEN Done...$COL_RESET"
}
