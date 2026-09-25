#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#
# Installs an additional daemon server over SSH (see remote_ssh.sh).
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"
# Settings of the server being added.
source "$STORAGE_ROOT/yiimp/.newconf.conf"
cd "$HOME/multipool/yiimp_multi" || exit 1
source remote_ssh.sh
PHP_VERSION="${PHP_VERSION:-$MULTIPOOL_DEFAULT_PHP_VERSION}"

daemon_files=(
	remote_daemon.sh motd.sh server_harden.sh firewall.sh ssh.sh
	ubuntu/etc/update-motd.d/daemon/00-header ubuntu/etc/update-motd.d/daemon/10-sysinfo
	ubuntu/etc/update-motd.d/daemon/90-footer
)
daemon_files=("${daemon_files[@]/#/$MP_REPO_DIR/}")

daemon_scripts=(
	remote_daemon.sh
	"motd.sh daemon"
	server_harden.sh
	"ssh.sh daemon"
)

mp_remote_install_server daemon "${DaemonUser}@${DaemonInternalIP}" "${DaemonPass:-}" \
	MP_DAEMON_KEYS daemon_files daemon_scripts

cd "$HOME/multipool/yiimp_multi" || exit 1
