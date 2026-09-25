#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#
# Installs the nginx configuration (the Ubuntu nginx package is used; the
# nginx.org repository is no longer added).
#####################################################

MP_STAGE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"
PHP_VERSION="${PHP_VERSION:-$MULTIPOOL_DEFAULT_PHP_VERSION}"

echo -e " Configuring NGINX...$COL_RESET"

# Make additional conf directories, move and generate needed configurations.
sudo mkdir -p /etc/nginx/cryptopool.builders
if [ ! -f /etc/nginx/nginx.conf.old ]; then
	sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.old
fi
sudo install -m 0644 "$MP_STAGE/nginx.conf" /etc/nginx/nginx.conf
for f in general.conf security.conf letsencrypt.conf; do
	sudo install -m 0644 "$MP_STAGE/$f" "/etc/nginx/cryptopool.builders/$f"
done
sed "s|@PHP_VERSION@|${PHP_VERSION}|g" "$MP_STAGE/php_fastcgi.conf" \
	| sudo tee /etc/nginx/cryptopool.builders/php_fastcgi.conf > /dev/null

# Removing default nginx site configs.
sudo rm -f /etc/nginx/conf.d/default.conf /etc/nginx/sites-enabled/default* /etc/nginx/sites-available/default*

restart_service "php${PHP_VERSION}-fpm"
echo -e "$GREEN Done...$COL_RESET"
exit 0
