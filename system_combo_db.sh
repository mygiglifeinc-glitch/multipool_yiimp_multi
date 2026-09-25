#!/usr/bin/env bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

clear
source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"
source "$HOME/multipool/yiimp_multi/system_base.sh"
source "$HOME/multipool/yiimp_multi/stratum_build.sh"

mp_system_base
mp_install_stratum_build_deps
mp_clone_yiimp

cd "$HOME/multipool/yiimp_multi" || exit 1
