#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#
# Builds and installs the stratum on a stratum server.
#   remote_stratum.sh [first|additional]
# "first" (the default) also installs addport and addport_multi, which are
# only used on the first stratum server.
#####################################################

MP_STAGE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"
source "$MP_STAGE/system_base.sh"
source "$MP_STAGE/stratum_build.sh"

echo -e " Building stratum server...$COL_RESET"

if [ "${1:-first}" = "first" ]; then
	# Install addport tools
	sudo install -m 0755 "$MP_STAGE/addport" /usr/bin/addport
	sudo install -m 0755 "$MP_STAGE/addport_multi_stratums" /usr/bin/addport_multi
fi
# Used by addport_multi to add a coin port on the other stratum servers.
sudo install -m 0755 "$MP_STAGE/remote.sh" "$STORAGE_ROOT/yiimp/remote.sh"
# Start/stop helper for the algo stratums
sudo install -m 0755 "$MP_STAGE/stratum" /usr/bin/stratum

mp_build_stratum "$DBInternalIP"

echo -e "$GREEN Stratum server build complete...$COL_RESET"
exit 0
