#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
cd "$HOME/multipool/yiimp_multi" || exit 1

apt_install lsb-release figlet update-motd \
	landscape-common update-notifier-common

sudo rm -rf /etc/update-motd.d/
sudo mkdir -p /etc/update-motd.d/
for f in 00-header 10-sysinfo 90-footer; do
	sudo install -m 0755 "ubuntu/etc/update-motd.d/db/$f" "/etc/update-motd.d/$f"
done

sudo tee /usr/bin/motd > /dev/null <<'EOF_MOTD'
#!/usr/bin/env bash
clear
run-parts /etc/update-motd.d/ | sudo tee /etc/motd
EOF_MOTD
sudo chmod 0755 /usr/bin/motd
cd "$HOME/multipool/yiimp_multi" || exit 1
