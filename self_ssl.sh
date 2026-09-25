#!/usr/bin/env bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"

# Installs self signed SSL
echo -e " Creating initial SSL certificate...$COL_RESET"

# Install openssl.
apt_install openssl

# Create a directory to store TLS-related things like "SSL" certificates.
sudo mkdir -p "$STORAGE_ROOT/ssl"
sudo chmod 0750 "$STORAGE_ROOT/ssl"

if [ ! -f "$STORAGE_ROOT/ssl/ssl_private_key.pem" ]; then
	# Generate a new private key and self-signed certificate. The umask makes
	# sure the key file is never readable by other users.
	CERT="$STORAGE_ROOT/ssl/${PRIMARY_HOSTNAME}-selfsigned-$(date +%Y%m%d).pem"
	hide_output sudo sh -c 'umask 077; openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 365 \
		-keyout "$1" -out "$2" -subj "/CN=$3"' sh \
		"$STORAGE_ROOT/ssl/ssl_private_key.pem" "$CERT" "$PRIMARY_HOSTNAME"
	sudo chmod 0644 "$CERT"

	# Symlink the certificate into the system certificate path, so system services
	# can find it.
	sudo ln -sfn "$CERT" "$STORAGE_ROOT/ssl/ssl_certificate.pem"
fi
sudo chmod 0600 "$STORAGE_ROOT/ssl/ssl_private_key.pem"

# Diffie-Hellman parameters: use the standard RFC 7919 ffdhe2048 group
# (instant) and fall back to generating 2048 bit parameters.
if [ ! -f /etc/nginx/dhparam.pem ]; then
	sudo mkdir -p /etc/nginx
	if ! sudo openssl genpkey -genparam -algorithm DH -pkeyopt group:ffdhe2048 -out /etc/nginx/dhparam.pem > /dev/null 2>&1; then
		hide_output sudo openssl dhparam -out /etc/nginx/dhparam.pem 2048
	fi
fi
echo -e "$GREEN Initial Self Signed SSL Generation completed...$COL_RESET"
exit 0
