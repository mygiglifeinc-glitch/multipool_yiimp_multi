#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#
# Installs the stratum server over SSH (see remote_ssh.sh).
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"
cd "$HOME/multipool/yiimp_multi" || exit 1
source remote_ssh.sh
PHP_VERSION="${PHP_VERSION:-$MULTIPOOL_DEFAULT_PHP_VERSION}"

stratum_files=(
	remote_system_stratum_server.sh stratum_build.sh remote_stratum.sh
	motd.sh server_harden.sh firewall.sh ssh.sh
	ubuntu/addport ubuntu/addport_multi_stratums ubuntu/remote.sh ubuntu/stratum
	ubuntu/etc/update-motd.d/stratum/00-header ubuntu/etc/update-motd.d/stratum/10-sysinfo
	ubuntu/etc/update-motd.d/stratum/90-footer
)
stratum_files=("${stratum_files[@]/#/$MP_REPO_DIR/}")

stratum_scripts=(
	remote_system_stratum_server.sh
	"remote_stratum.sh first"
	"motd.sh stratum"
	server_harden.sh
	"ssh.sh stratum"
)

mp_remote_install_server stratum "${StratumUser}@${StratumInternalIP}" "${StratumPass:-}" \
	MP_STRATUM_KEYS stratum_files stratum_scripts

cd "$HOME/multipool/yiimp_multi" || exit 1
