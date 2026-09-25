#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#
# Adds (or updates) a dedicated port stratum for a coin on this stratum
# server. Used by addport on the local server and by addport_multi on the
# other stratum servers (the script is streamed to them over SSH).
#   remote.sh SYMBOL algo port [nicehash value]
#####################################################

source /etc/functions.sh
source /etc/multipool.conf

coinsymbol=${1^^}
coinalgo=${2,,}
coinport=${3:-}
nicevalue=${4:-}
coinsymbollower=${coinsymbol,,}

if ! [[ "$coinsymbol" =~ ^[A-Z0-9]+$ && "$coinalgo" =~ ^[a-z0-9]+$ && "$coinport" =~ ^[0-9]+$ ]] \
	|| ! [[ -z "$nicevalue" || "$nicevalue" =~ ^[0-9]+$ ]]; then
	echo "usage: $0 SYMBOL algo port [nicehash value]"
	exit 1
fi

config_dir="$STORAGE_ROOT/yiimp/site/stratum/config"
cd "$config_dir" || exit 1
if [ ! -f "$coinalgo.conf" ]; then
	echo "Sorry that algo config file doesn't exist in $config_dir please double check and try again."
	exit 1
fi

coin_conf="$coinsymbollower.$coinalgo.conf"
if [ -f "$coin_conf" ]; then
	# Existing coin: only update the port.
	sed -i "s/^port = .*/port = ${coinport}/" "$coin_conf"
	echo "Port updated! Remember to update your blocknotify line!!"
else
	# Since this is a new symbol we are going to exclude it from the other
	# coin configs of this algo first.
	for r in *."$coinalgo".conf; do
		[ -e "$r" ] || continue
		if ! grep -Fxq "exclude = ${coinsymbol}" "$r"; then
			printf '[WALLETS]\nexclude = %s\n' "$coinsymbol" >> "$r"
		fi
	done
	# Copy the default algo.conf to the new symbol.algo.conf
	cp "$coinalgo.conf" "$coin_conf"
	# Insert the port in to the new symbol.algo.conf
	sed -i "s/^port = .*/port = ${coinport}/" "$coin_conf"
	# If setting a nicehash value
	if [ -n "$nicevalue" ]; then
		sed -i "/^difficulty =/a nicehash = ${nicevalue}" "$coin_conf"
	fi
	# Insert the include in to the new symbol.algo.conf
	printf '[WALLETS]\ninclude = %s\n' "$coinsymbol" >> "$coin_conf"
	chmod 0640 "$coin_conf"
fi

# Prevent duplications when addport is run multiple times for the same coin.
if ! grep -Fxq "exclude = ${coinsymbol}" "$coinalgo.conf"; then
	# Insert the exclude in to algo.conf
	printf '[WALLETS]\nexclude = %s\n' "$coinsymbol" >> "$coinalgo.conf"
else
	echo "${coinsymbol} is already in $coinalgo.conf, skipping... Which means you are trying to run this multiple times for the same coin."
fi

# New coin stratum start file
start_file="$config_dir/stratum.${coinsymbollower}"
cat > "$start_file" <<EOF_START
#!/usr/bin/env bash
#####################################################
# Source code from https://codereview.stackexchange.com/questions/55077/small-bash-script-to-start-and-stop-named-services
# Updated by cryptopool.builders for crypto use...
#
# stratum.${coinsymbollower} start|stop|restart ${coinsymbollower}
#####################################################

source /etc/multipool.conf
STRATUM_DIR=\$STORAGE_ROOT/yiimp/site/stratum

function stratum_start {
	screen -dmS ${coinsymbollower} bash "\$STRATUM_DIR/run.sh" ${coinsymbollower}.${coinalgo}
}

function stratum_stop {
	screen -X -S ${coinsymbollower} quit > /dev/null 2>&1
}

case "\${1:-}" in
	start | stop | restart) cmd=\$1 ;;
	*)
		echo "usage: \$0 [start|stop|restart] ${coinsymbollower}"
		exit 1
		;;
esac
shift

for name; do
	case "\$name" in
		${coinsymbollower})
			case "\$cmd" in
				start) stratum_start ;;
				stop) stratum_stop ;;
				restart)
					stratum_stop
					sleep 1
					stratum_start
					;;
			esac
			;;
		*) sudo systemctl "\$cmd" "\$name" ;;
	esac
done
EOF_START
chmod 0755 "$start_file"
sudo install -m 0755 "$start_file" "/usr/bin/stratum.${coinsymbollower}"

ufw_allow "${coinport}/tcp"

# Start the stratum at boot (only one entry per coin).
cron_line="@reboot sleep 10 && /usr/bin/stratum.${coinsymbollower} start ${coinsymbollower}"
(crontab -l 2> /dev/null | grep -vF "stratum.${coinsymbollower} start"; echo "$cron_line") | crontab -

"/usr/bin/stratum.${coinsymbollower}" restart "${coinsymbollower}"
exit 0
