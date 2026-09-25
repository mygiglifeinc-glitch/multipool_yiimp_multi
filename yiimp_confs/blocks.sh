#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#
# Sourced by remote_web_web_server.sh. Creates the blocks.sh cron loop.
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"
PHP_VERSION="${PHP_VERSION:-$MULTIPOOL_DEFAULT_PHP_VERSION}"

# Create blocks.sh
sudo tee "$STORAGE_ROOT/yiimp/site/crons/blocks.sh" > /dev/null <<EOF_CRON
#!/usr/bin/env bash

PHP_CLI=($(printf '%q' "/usr/bin/php${PHP_VERSION}") -d max_execution_time=60)

DIR=$(printf '%q' "${STORAGE_ROOT}/yiimp/site/web/")
cd "\${DIR}" || exit 1

date
echo "started in \${DIR}"

while true; do
	"\${PHP_CLI[@]}" runconsole.php cronjob/runBlocks
	sleep 20
done
EOF_CRON
sudo chmod +x "$STORAGE_ROOT/yiimp/site/crons/blocks.sh"
