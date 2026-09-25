#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#
# Sourced by remote_web_web_server.sh. Creates /etc/yiimp/keys.php, which
# holds secrets: readable by root and the web server group only.
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"

#Create keys file
sudo mkdir -p /etc/yiimp
sudo tee /etc/yiimp/keys.php > /dev/null <<EOF_KEYS
<?php
// Sample config file to put in /etc/yiimp/keys.php
define('YIIMP_MYSQLDUMP_USER', $(php_quote "$YiiMPPanelName"));
define('YIIMP_MYSQLDUMP_PASS', $(php_quote "$PanelUserDBPassword"));
define('YIIMP_MYSQLDUMP_PATH', $(php_quote "${STORAGE_ROOT}/yiimp/site/backup"));
// Keys required to create/cancel orders and access your balances/deposit addresses
define('EXCH_BITTREX_SECRET', '');
define('EXCH_BITSTAMP_SECRET', '');
define('EXCH_BINANCE_SECRET', '');
define('EXCH_BLEUTRADE_SECRET', '');
define('EXCH_BTER_SECRET', '');
define('EXCH_CCEX_SECRET', '');
define('EXCH_CEXIO_SECRET', '');
define('EXCH_COINMARKETS_PASS', '');
define('EXCH_CRYPTOPIA_SECRET', '');
define('EXCH_EMPOEX_SECKEY', '');
define('EXCH_HITBTC_SECRET', '');
define('EXCH_KRAKEN_SECRET', '');
define('EXCH_KUCOIN_SECRET', '');
define('EXCH_LIVECOIN_SECRET', '');
define('EXCH_NOVA_SECRET', '');
define('EXCH_POLONIEX_SECRET', '');
define('EXCH_STOCKSEXCHANGE_SECRET', '');
define('EXCH_YOBIT_SECRET', '');
EOF_KEYS
sudo chown root:www-data /etc/yiimp/keys.php
sudo chmod 0640 /etc/yiimp/keys.php
