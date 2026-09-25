#!/usr/bin/env bash
#####################################################
# Source code https://github.com/end222/pacmenu
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh

RESULT=""
# --nocancel: only ESC returns an empty result, show the menu again then.
while [ -z "$RESULT" ] || [ "$RESULT" = " " ]; do
	RESULT=$(dialog --stdout --nocancel --default-item 1 --title "Ultimate Crypto-Server Setup Installer v2.0.0" --menu "Choose one" -1 63 10 \
		' ' "- Required if your Host does Not provide Private IPs -" \
		1 "Install Wireguard Network" \
		' ' "- Three Server Configuration -" \
		2 "YiiMP - DB-Stratum, Web, Daemon" \
		' ' "- Four Server Configuration -" \
		3 "YiiMP - DB, Web, Stratum, Daemon" \
		' ' "- Add Additional Servers -" \
		4 "YiiMP - Additional Stratum Server(s)" \
		5 "YiiMP - Additional Daemon Server(s)" \
		6 Exit)
done

cd "$HOME/multipool/yiimp_multi" || exit 1
case "$RESULT" in
	1)
		clear
		source wireguard_menu.sh
		;;
	2)
		clear
		source install_combo.sh
		;;
	3)
		clear
		source install_multi.sh
		;;
	4)
		clear
		source install_add_strat.sh
		;;
	5)
		clear
		source install_add_daemon.sh
		;;
	6)
		clear
		exit
		;;
esac
