#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#
# Installs the web server over SSH (see remote_ssh.sh).
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"
cd "$HOME/multipool/yiimp_multi" || exit 1
source remote_ssh.sh
PHP_VERSION="${PHP_VERSION:-$MULTIPOOL_DEFAULT_PHP_VERSION}"

# Files copied to the web server's staging directory.
web_files=(
	remote_system_web_server.sh self_ssl.sh nginx_setup.sh nginx_site.sh
	remote_web_web_server.sh server_cleanup.sh send_mail.sh motd.sh
	server_harden.sh firewall.sh ssh.sh first_boot.sh
	ubuntu/screens
	ubuntu/etc/update-motd.d/00-header ubuntu/etc/update-motd.d/10-sysinfo ubuntu/etc/update-motd.d/90-footer
	nginx_confs/nginx.conf nginx_confs/general.conf nginx_confs/letsencrypt.conf
	nginx_confs/php_fastcgi.conf nginx_confs/security.conf
	yiimp_confs/yiimpserverconfig.sh yiimp_confs/blocks.sh yiimp_confs/keys.sh
	yiimp_confs/loop2.sh yiimp_confs/main.sh
)
web_files=("${web_files[@]/#/$MP_REPO_DIR/}")

# Scripts run on the web server, in order.
web_scripts=(
	remote_system_web_server.sh
	self_ssl.sh
	nginx_setup.sh
	remote_web_web_server.sh
	server_cleanup.sh
	send_mail.sh
	"motd.sh web"
	server_harden.sh
	"ssh.sh web"
)

mp_remote_install_server web "${WebUser}@${WebInternalIP}" "${WebPass:-}" MP_WEB_KEYS web_files web_scripts

cd "$HOME/multipool/yiimp_multi" || exit 1
