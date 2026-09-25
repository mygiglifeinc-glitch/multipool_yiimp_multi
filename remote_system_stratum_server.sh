#!/usr/bin/env bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

MP_STAGE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"
source "$MP_STAGE/system_base.sh"
source "$MP_STAGE/stratum_build.sh"

echo -e " Building stratum server...$COL_RESET"

mp_system_base

mp_install_stratum_build_deps

mp_clone_yiimp
echo -e "$GREEN Stratum server build completed...$COL_RESET"
exit 0
