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
PHP_VERSION="${PHP_VERSION:-$MULTIPOOL_DEFAULT_PHP_VERSION}"

echo -e " Building web server system files...$COL_RESET"

mp_system_base

# PHP from the ondrej/php PPA, when the PPA supports this Ubuntu release.
echo -e " Installing Ondrej PHP PPA...$COL_RESET"
if curl -fsS --max-time 20 -o /dev/null "https://ppa.launchpadcontent.net/ondrej/php/ubuntu/dists/${UBUNTU_CODENAME}/Release"; then
	hide_output sudo add-apt-repository -y ppa:ondrej/php
else
	echo -e "$YELLOW The ondrej/php PPA does not support ${UBUNTU_CODENAME} yet, using the Ubuntu PHP packages.$COL_RESET"
fi
hide_output sudo apt-get update
echo -e "$GREEN Done...$COL_RESET"

# Fall back to the release's own PHP version if the configured one is not
# available (e.g. no PPA for this release yet).
if ! apt-cache show "php${PHP_VERSION}-fpm" > /dev/null 2>&1; then
	distro_php=$(apt-cache depends php-fpm 2>/dev/null | sed -n 's/.*Depends: php\([0-9][0-9.]*\)-fpm.*/\1/p' | head -n 1)
	if [ -z "$distro_php" ]; then
		echo -e "$RED PHP ${PHP_VERSION} is not available for this Ubuntu release.$COL_RESET"
		exit 1
	fi
	echo -e "$YELLOW PHP ${PHP_VERSION} is not available, using PHP ${distro_php} instead.$COL_RESET"
	PHP_VERSION=$distro_php
	# Remember the version actually installed for the nginx and cron setup.
	sudo sed -i "s/^PHP_VERSION=.*/PHP_VERSION=${PHP_VERSION}/" "$STORAGE_ROOT/yiimp/.yiimp.conf" /etc/multipool.conf
fi

echo -e " Installing YiiMP Required system packages...$COL_RESET"
php_packages=()
for ext in fpm common gd mysql cli curl intl xml xsl zip mbstring bcmath; do
	php_packages+=("php${PHP_VERSION}-${ext}")
done
# Extensions that are not built for every PHP version / release.
for ext in opcache imap pspell sqlite3 tidy memcache imagick; do
	if apt-cache show "php${PHP_VERSION}-${ext}" > /dev/null 2>&1; then
		php_packages+=("php${PHP_VERSION}-${ext}")
	fi
done
apt_install "${php_packages[@]}" memcached imagemagick mariadb-client \
	nginx certbot python3-certbot-nginx pwgen openssl
sudo systemctl enable --now "php${PHP_VERSION}-fpm" > /dev/null 2>&1 || true
echo -e "$GREEN Done...$COL_RESET"

mp_clone_yiimp
echo -e "$GREEN Web server system completed...$COL_RESET"
exit 0
