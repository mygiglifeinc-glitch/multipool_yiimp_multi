#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#
# Sourced by remote_web_web_server.sh. Creates serverconfig.php, which holds
# the database password: readable by root and the web server group only.
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"

sudo mkdir -p "$STORAGE_ROOT/yiimp/site/configuration"
sudo tee "$STORAGE_ROOT/yiimp/site/configuration/serverconfig.php" > /dev/null <<EOF
<?php
ini_set('date.timezone', 'UTC');
define('YAAMP_LOGS', $(php_quote "${STORAGE_ROOT}/yiimp/site/log"));
define('YAAMP_HTDOCS', $(php_quote "${STORAGE_ROOT}/yiimp/site/web"));

define('YAAMP_BIN', '/bin');

define('YAAMP_DBHOST', $(php_quote "$DBInternalIP"));
define('YAAMP_DBNAME', $(php_quote "$YiiMPDBName"));
define('YAAMP_DBUSER', $(php_quote "$YiiMPPanelName"));
define('YAAMP_DBPASSWORD', $(php_quote "$PanelUserDBPassword"));

define('YAAMP_PRODUCTION', true);
define('YAAMP_RENTAL', false);

define('YAAMP_LIMIT_ESTIMATE', false);

define('YAAMP_FEES_MINING', 0.5);
define('YAAMP_FEES_EXCHANGE', 2);
define('YAAMP_FEES_RENTING', 2);
define('YAAMP_TXFEE_RENTING_WD', 0.002);

define('YAAMP_PAYMENTS_FREQ', 3*60*60);
define('YAAMP_PAYMENTS_MINI', 0.001);

define('YAAMP_ALLOW_EXCHANGE', false);
define('YIIMP_PUBLIC_EXPLORER', false);
define('YIIMP_PUBLIC_BENCHMARK', false);

define('YIIMP_FIAT_ALTERNATIVE', 'USD'); // USD is main
define('YAAMP_USE_NICEHASH_API', false);

define('YAAMP_BTCADDRESS', '12Pt3vQhQpXvyzBd5qcoL17ouhNFyihyz5');

define('YAAMP_SITE_URL', $(php_quote "$DomainName"));
define('YAAMP_STRATUM_URL', $(php_quote "$StratumURL")); // change if your stratum server is on a different host
define('YAAMP_SITE_NAME', 'CryptoPool.Builders');
define('YAAMP_ADMIN_EMAIL', $(php_quote "$SupportEmail"));
define('YAAMP_ADMIN_IP', $(php_quote "$PublicIP")); // samples: "80.236.118.26,90.234.221.11" or "10.0.0.1/8"

define('YAAMP_ADMIN_WEBCONSOLE', true);
define('YAAMP_CREATE_NEW_COINS', false);
define('YAAMP_NOTIFY_NEW_COINS', false);

define('YAAMP_DEFAULT_ALGO', 'x11');

define('YAAMP_USE_NGINX', true);

// Exchange public keys (private keys are in a separate config file)
define('EXCH_CRYPTOPIA_KEY', '');
define('EXCH_POLONIEX_KEY', '');
define('EXCH_BITTREX_KEY', '');
define('EXCH_BLEUTRADE_KEY', '');
define('EXCH_BTER_KEY', '');
define('EXCH_YOBIT_KEY', '');
define('EXCH_CCEX_KEY', '');
define('EXCH_CEXIO_ID', '');
define('EXCH_CEXIO_KEY', '');
define('EXCH_COINMARKETS_USER', '');
define('EXCH_COINMARKETS_PIN', '');
define('EXCH_CREX24_KEY', '');
define('EXCH_BINANCE_KEY', '');
define('EXCH_BITSTAMP_ID', '');
define('EXCH_BITSTAMP_KEY', '');
define('EXCH_HITBTC_KEY', '');
define('EXCH_KRAKEN_KEY', '');
define('EXCH_KUCOIN_KEY', '');
define('EXCH_LIVECOIN_KEY', '');
define('EXCH_NOVA_KEY', '');
define('EXCH_STOCKSEXCHANGE_KEY', '');

// Automatic withdraw to Yaamp btc wallet if btc balance > 0.3
define('EXCH_AUTO_WITHDRAW', 0.3);

// nicehash keys deposit account & amount to deposit at a time
define('NICEHASH_API_KEY','521c254d-8cc7-4319-83d2-ac6c604b5b49');
define('NICEHASH_API_ID','9205');
define('NICEHASH_DEPOSIT','3J9tapPoFCtouAZH7Th8HAPsD8aoykEHzk');
define('NICEHASH_DEPOSIT_AMOUNT','0.01');

\$cold_wallet_table = array(
'12Pt3vQhQpXvyzBd5qcoL17ouhNFyihyz5' => 0.10,
);

// Sample fixed pool fees
\$configFixedPoolFees = array(
'zr5' => 2.0,
'scrypt' => 20.0,
'sha256' => 5.0,
);

// Sample custom stratum ports
\$configCustomPorts = array(
// 'x11' => 7000,
);

// mBTC Coefs per algo (default is 1.0)
\$configAlgoNormCoef = array(
// 'x11' => 5.0,
);
EOF
sudo chown root:www-data "$STORAGE_ROOT/yiimp/site/configuration/serverconfig.php"
sudo chmod 0640 "$STORAGE_ROOT/yiimp/site/configuration/serverconfig.php"
