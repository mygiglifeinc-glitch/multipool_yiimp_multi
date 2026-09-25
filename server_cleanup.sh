#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

MP_STAGE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"

echo -e " Installing cron screens to crontab...$COL_RESET"
start_script="$STORAGE_ROOT/yiimp/starts/screens.start.sh"
# Add the @reboot entry once, even when the installer is run again.
(crontab -l 2> /dev/null | grep -vF "screens.start.sh"; echo "@reboot sleep 20 && $(printf '%q' "$start_script")") | crontab -
sudo install -m 0755 "$MP_STAGE/first_boot.sh" "$STORAGE_ROOT/yiimp/first_boot.sh"
echo -e "$GREEN Done...$COL_RESET"

echo -e " Creating YiiMP Screens startup script...$COL_RESET"
sudo mkdir -p "$STORAGE_ROOT/yiimp/starts"
sudo tee "$start_script" > /dev/null <<'EOF_START'
#!/usr/bin/env bash
################################################################################
# Author: cryptopool.builders
#
#
# Program: yiimp screen startup script
#
# BTC Donation: 12Pt3vQhQpXvyzBd5qcoL17ouhNFyihyz5
#
################################################################################
source /etc/multipool.conf
# Ugly way to remove junk coins from initial YiiMP database on first boot
if [ -f "$STORAGE_ROOT/yiimp/first_boot.sh" ]; then
	bash "$STORAGE_ROOT/yiimp/first_boot.sh"
fi
LOG_DIR=$STORAGE_ROOT/yiimp/site/log
CRONS=$STORAGE_ROOT/yiimp/site/crons
touch "$LOG_DIR/debug.log"
screen -dmS main bash "$CRONS/main.sh"
screen -dmS loop2 bash "$CRONS/loop2.sh"
screen -dmS blocks bash "$CRONS/blocks.sh"
screen -dmS debug tail -f "$LOG_DIR/debug.log"
EOF_START
sudo chmod 0755 "$start_script"

sudo tee "$STORAGE_ROOT/yiimp/.prescreens.start.conf" > /dev/null <<'EOF_PRE'
source /etc/multipool.conf
LOG_DIR=$STORAGE_ROOT/yiimp/site/log
CRONS=$STORAGE_ROOT/yiimp/site/crons
EOF_PRE
sudo chmod 0644 "$STORAGE_ROOT/yiimp/.prescreens.start.conf"

# Load the variables in interactive shells (only added once).
for line in "source /etc/multipool.conf" "source $(printf '%q' "$STORAGE_ROOT/yiimp/.prescreens.start.conf")"; do
	grep -qxF "$line" ~/.bashrc 2> /dev/null || echo "$line" >> ~/.bashrc
done
echo -e "$GREEN Done...$COL_RESET"
exit 0
