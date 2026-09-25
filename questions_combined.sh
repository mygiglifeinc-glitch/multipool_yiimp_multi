#!/usr/bin/env bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
cd "$HOME/multipool/yiimp_multi" || exit 1
source questions_common.sh
PHP_VERSION="${PHP_VERSION:-$MULTIPOOL_DEFAULT_PHP_VERSION}"

wireguard=false
if grep -qs '^wireguard=true' "$STORAGE_ROOT/yiimp/.wireguard_public.conf"; then
	wireguard=true
fi

ask_yesno "Using Sub-Domain" "Are you using a sub-domain for the main website domain? Example pool.example.com?" UsingSubDomain

if [ -z "${DomainName:-}" ]; then
	ask_input "Domain Name" \
		"Enter your domain name. If using a subdomain enter the full domain as in pool.example.com
\n\nDo not add www. to the domain name.
\n\nDomain Name:" \
		example.com DomainName is_valid_hostname
fi

if [ -z "${StratumURL:-}" ]; then
	ask_input "Stratum URL" \
		"Enter your stratum URL. It is recommended to use another subdomain such as stratum.$DomainName
\n\nDo not add www. to the domain name.
\n\nStratum URL:" \
		"stratum.$DomainName" StratumURL is_valid_hostname
fi

ask_yesno "Install SSL" "Would you like the system to install SSL automatically?" InstallSSL

if [ -z "${SupportEmail:-}" ]; then
	ask_input "System Email" \
		"Enter an email address for the system to send alerts and other important messages.
\n\nSystem Email:" \
		root@localhost SupportEmail
fi

if [ -z "${AdminPanel:-}" ]; then
	ask_input "Admin Panel Location" \
		"Enter your desired location name for admin access..
\n\nOnce set you will access the YiiMP admin at $DomainName/site/AdminPortal
\n\nDesired Admin Panel Location:" \
		AdminPortal AdminPanel is_valid_name
fi

ask_yesno "Use AutoExchange" "Would you like the stratum to be built with autoexchange enabled?" AutoExchange
ask_yesno "Use Dedicated Coin Ports" "Would you like YiiMP to be built with dedicated coin ports?" CoinPort

if [ -z "${PublicIP:-}" ]; then
	ask_input "Your Public IP" \
		"Enter your public IP from the remote system you will access your admin panel from.
\n\nWe have guessed your public IP from the IP used to access this system.
\n\nGo to whatsmyip.org if you are unsure this is your public IP.
\n\nYour Public IP:" \
		"$(guess_client_ip)" PublicIP
fi

# Get the IP addresses of the local network interface(s).
if [ -z "${DBInternalIP:-}" ]; then
	ask_input "DB Server Private IP" \
		"Enter the private IP address of the DB (this) Server, as given to you by your provider.
\n\nIf you do not have one from your provider leave the Wireguard default below.
\n\nPrivate IP address:" \
		10.0.0.2 DBInternalIP is_valid_ipv4
fi

if [ -z "${WebInternalIP:-}" ]; then
	ask_input "Web Server Private IP" \
		"Enter the private IP address of the Web Server, as given to you by your provider.
\n\nIf you do not have one from your provider leave the Wireguard default below.
\n\nPrivate IP address:" \
		10.0.0.3 WebInternalIP is_valid_ipv4
fi

if [ -z "${WebUser:-}" ]; then
	ask_input "Web Server User Name" \
		"Enter the user name for the Web Server.
\n\nThis is required for setup to complete.
\n\nWeb Server User Name:" \
		yiimpadmin WebUser is_valid_username
fi

if [ -z "${WebPass:-}" ]; then
	ask_input "Web Server User Password" \
		"Enter the users password for the Web Server.
\n\nThis is required for setup to complete.
\n\nWhen pasting your password CTRL+V does NOT work, you must either SHIFT+RightMouseClick or SHIFT+INSERT!!
\n\nWeb Server User Password:" \
		password WebPass
fi

if [ -z "${DaemonInternalIP:-}" ]; then
	ask_input "Daemon Server Private IP" \
		"Enter the private IP address of the Daemon Server, as given to you by your provider.
\n\nIf you do not have one from your provider leave the Wireguard default below.
\n\nPrivate IP address:" \
		10.0.0.5 DaemonInternalIP is_valid_ipv4
fi

if [ -z "${DaemonUser:-}" ]; then
	ask_input "Daemon Server User Name" \
		"Enter the user name for the Daemon Server.
\n\nThis is required for setup to complete.
\n\nDaemon Server User Name:" \
		yiimpadmin DaemonUser is_valid_username
fi

if [ -z "${DaemonPass:-}" ]; then
	ask_input "Daemon Server User Password" \
		"Enter the users password for the Daemon Server.
\n\nThis is required for setup to complete.
\n\nWhen pasting your password CTRL+V does NOT work, you must either SHIFT+RightMouseClick or SHIFT+INSERT!!
\n\nDaemon Server User Password:" \
		password DaemonPass
fi

db_password_error="Database passwords must be at least 12 characters long and may only contain letters, digits and . _ + = @ % : , ~ -"

if [ -z "${DBRootPassword:-}" ]; then
	ask_input "Database Root Password" \
		"Enter your desired database root password.
\n\nYou may use the system generated password shown.
\n\nDesired Database Password:" \
		"$(generate_password 32)" DBRootPassword is_valid_db_password "$db_password_error"
fi

if [ -z "${PanelUserDBPassword:-}" ]; then
	ask_input "Database Panel Password" \
		"Enter your desired database panel password.
\n\nYou may use the system generated password shown.
\n\nDesired Database Password:" \
		"$(generate_password 32)" PanelUserDBPassword is_valid_db_password "$db_password_error"
fi

if [ -z "${StratumUserDBPassword:-}" ]; then
	ask_input "Database Stratum Password" \
		"Enter your desired database stratum password.
\n\nYou may use the system generated password shown.
\n\nDesired Database Password:" \
		"$(generate_password 32)" StratumUserDBPassword is_valid_db_password "$db_password_error"
fi

clear

response=0
dialog --title "Verify Your Responses" \
	--yesno "Please verify your answers to continue setup:

Use Sub-Domain : ${UsingSubDomain}
Domain Name      : ${DomainName}
Stratum URL      : ${StratumURL}
Install SSL      : ${InstallSSL}
System Email     : ${SupportEmail}
Admin Location   : ${AdminPanel}
Dedicated Coin Ports : ${CoinPort}
AutoExchange : ${AutoExchange}
Your Public IP   : ${PublicIP}
DB Internal IP   : ${DBInternalIP}
Web User : ${WebUser}
Web Password : ${WebPass}
WEB Internal IP  : ${WebInternalIP}
Daemon User : ${DaemonUser}
Daemon Password : ${DaemonPass}
Daemon Internal IP : ${DaemonInternalIP}" 25 60 || response=$?

# Get exit status
# 0 means user hit [yes] button.
# 1 means user hit [no] button.
# 255 means user hit [Esc] key.
case $response in
	0)
		# To increase security the yiimpfrontend DB name, panel and stratum user
		# names and the blocknotify password are randomly generated, so each
		# installation is more secure. We do it here to save the variables in
		# the global .yiimp.conf file.
		YiiMPDBName=$(generate_password 13)
		StratumDBUser=Stratum$(generate_password 13)
		YiiMPPanelName=Panel$(generate_password 13)
		blckntifypass=$(generate_password 32)
		PRIMARY_HOSTNAME=$DomainName
		# The stratum runs on this (DB) server.
		StratumInternalIP=$DBInternalIP
		set_yiimp_repo

		# Save the global options in $STORAGE_ROOT/yiimp/.yiimp.conf so that
		# standalone tools know where to look for data. It holds the database
		# passwords, so only this user can read it. The SSH passwords of the
		# other servers are only kept in memory while installing.
		sudo mkdir -p "$STORAGE_ROOT/yiimp"
		write_conf_file -m 600 "$STORAGE_ROOT/yiimp/.yiimp.conf" \
			STORAGE_USER STORAGE_ROOT PRIMARY_HOSTNAME PHP_VERSION \
			DomainName UsingSubDomain StratumURL InstallSSL SupportEmail \
			AdminPanel PublicIP CoinPort AutoExchange \
			DBInternalIP WebInternalIP StratumInternalIP DaemonInternalIP \
			WebUser DaemonUser \
			YiiMPDBName DBRootPassword YiiMPPanelName PanelUserDBPassword \
			StratumDBUser StratumUserDBPassword blckntifypass \
			wireguard YiiMPRepo YiiMPBranch
		;;
	1)
		# Start over
		clear
		unset UsingSubDomain DomainName StratumURL InstallSSL SupportEmail DBInternalIP \
			WebInternalIP WebUser WebPass \
			DaemonInternalIP DaemonUser DaemonPass AutoExchange CoinPort PublicIP \
			DBRootPassword PanelUserDBPassword StratumUserDBPassword AdminPanel
		source questions_combined.sh
		;;
	*)
		clear
		echo "User canceled installation"
		exit 0
		;;
esac

cd "$HOME/multipool/yiimp_multi" || exit 1
