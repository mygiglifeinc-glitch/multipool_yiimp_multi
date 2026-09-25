#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"

echo -e " Installing mail system...$COL_RESET"

sudo hostnamectl set-hostname "${DomainName}"

sudo debconf-set-selections <<< "postfix postfix/mailname string ${PRIMARY_HOSTNAME}"
sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt_install mailutils postfix

# Only send mail from this server, never accept it from the network.
sudo postconf -e "inet_interfaces = loopback-only"
# shellcheck disable=SC2016
sudo postconf -e 'mydestination = $myhostname, localhost.$mydomain, $mydomain'
restart_service postfix

whoami=$(whoami)
# Forward mail for root and the installing user to the support address.
for alias_user in root "$whoami"; do
	sudo sed -i "/^${alias_user}:/d" /etc/aliases
	printf '%s: %s\n' "$alias_user" "$SupportEmail" | sudo tee -a /etc/aliases > /dev/null
done
sudo newaliases
sudo usermod -aG mail "$whoami"
echo -e "$GREEN Done...$COL_RESET"
exit 0
