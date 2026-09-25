#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#
# Installs the MOTD and the helper commands of a remote server.
#   motd.sh web|stratum|daemon
#####################################################

MP_STAGE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source /etc/functions.sh
source /etc/multipool.conf

apt_install lsb-release figlet update-motd \
	landscape-common update-notifier-common

sudo rm -rf /etc/update-motd.d/
sudo mkdir -p /etc/update-motd.d/
for f in 00-header 10-sysinfo 90-footer; do
	sudo install -m 0755 "$MP_STAGE/$f" "/etc/update-motd.d/$f"
done

case "${1:-web}" in
	web)
		sudo install -m 0755 "$MP_STAGE/screens" /usr/bin/screens ;;
	stratum)
		# /usr/bin/stratum is installed by remote_stratum.sh
		;;
esac

sudo tee /usr/bin/motd > /dev/null <<'EOF_MOTD'
#!/usr/bin/env bash
clear
run-parts /etc/update-motd.d/ | sudo tee /etc/motd
EOF_MOTD
sudo chmod 0755 /usr/bin/motd
exit 0
