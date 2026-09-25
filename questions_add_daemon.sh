#!/usr/bin/env bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"
cd "$HOME/multipool/yiimp_multi" || exit 1
source questions_common.sh
PHP_VERSION="${PHP_VERSION:-$MULTIPOOL_DEFAULT_PHP_VERSION}"

wireguard=false
if grep -qs '^wireguard=true' "$STORAGE_ROOT/yiimp/.wireguard_public.conf"; then
	wireguard=true
fi

# Get the IP addresses of the local network interface(s).
if [ -z "${NewDaemonInternalIP:-}" ]; then
	ask_input "Daemon Server Private IP" \
		"Enter the private IP address of the Daemon Server, as given to you by your provider.
\n\nIf you do not have one from your provider enter the IP you assigned with Wireguard.
\n\nPrivate IP address:" \
		10.0.0.x NewDaemonInternalIP is_valid_ipv4
fi

if [ -z "${NewDaemonUser:-}" ]; then
	ask_input "Daemon Server User Name" \
		"Enter the user name of the Daemon Server.
\n\nThis is required for setup to complete.
\n\nDaemon Server User Name:" \
		yiimpadmin NewDaemonUser is_valid_username
fi

if [ -z "${NewDaemonPass:-}" ]; then
	ask_input "Daemon Server User Password" \
		"Enter the user password of the Daemon Server.
\n\nThis is required for setup to complete.
\n\nWhen pasting your password CTRL+V does NOT work, you must either SHIFT+RightMouseClick or SHIFT+INSERT!!
\n\nDaemon Server User Password:" \
		password NewDaemonPass
fi

# Installations made with this version of the installer know the
# blocknotify password; older ones have to look it up.
if [ -z "${blckntifypass:-}" ]; then
	ask_input "Blocknotify Password" \
		"Enter the existing blocknotify password from the first stratum server.
\n\nTo get this log in to your first stratum server and type:
\n\ncat ${STORAGE_ROOT}/yiimp/site/stratum/config/a5a.conf
\n\nThe blocknotify password is the first password in the TCP section.
\n\nRemember to shift + right click to paste!
\n\nBlocknotify Password:" \
		blocknotifypassword blckntifypass is_valid_name
fi

#Generate random conf file name.
generate=$(generate_password 12)
DaemonUser=$NewDaemonUser
DaemonPass=$NewDaemonPass
DaemonInternalIP=$NewDaemonInternalIP
set_yiimp_repo

# Save the options of the new server in $STORAGE_ROOT/yiimp/.newconf.conf
# (and a copy with a random name, as a record of the servers added).
write_conf_file -m 600 "$STORAGE_ROOT/yiimp/.$generate.conf" \
	STORAGE_USER STORAGE_ROOT PHP_VERSION DaemonUser DaemonInternalIP blckntifypass wireguard YiiMPRepo
sudo install -m 0600 -o "$(id -un)" -g "$(id -gn)" "$STORAGE_ROOT/yiimp/.$generate.conf" "$STORAGE_ROOT/yiimp/.newconf.conf"
