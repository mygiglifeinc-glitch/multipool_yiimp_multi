#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#
# MariaDB helpers for the DB server. This file only defines functions.
# SQL is always passed to the server on stdin so that no password ever
# appears on a command line.
#####################################################

# Quote a string as an SQL string literal.
function sql_quote {
	local s=${1//\\/\\\\}
	s=${s//\'/\\\'}
	printf "'%s'" "$s"
}

# Quote a string as an SQL identifier.
function sql_ident {
	printf '`%s`' "${1//\`/\`\`}"
}

# Quote a value for a MySQL option file (.my.cnf).
function mycnf_quote {
	local s=${1//\\/\\\\}
	s=${s//\"/\\\"}
	printf '"%s"' "$s"
}

# Run SQL read from stdin as the MariaDB root user (unix socket auth).
function mp_sql {
	sudo mariadb --batch "$@"
}

# Install MariaDB from the Ubuntu archive and secure it like
# mariadb-secure-installation does: no anonymous users, no remote root, no
# test database. root keeps unix_socket authentication and can also log in
# locally with the chosen root password.
function mp_mariadb_install {
	echo -e " Installing MariaDB...$COL_RESET"
	apt_install mariadb-server mariadb-client
	sudo systemctl enable --now mariadb > /dev/null 2>&1 || true
	echo -e "$GREEN Done...$COL_RESET"

	echo -e " Securing MariaDB...$COL_RESET"
	mp_sql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket OR mysql_native_password USING PASSWORD($(sql_quote "$DBRootPassword"));
DELETE FROM mysql.global_priv WHERE User='';
DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
	echo -e "$GREEN Done...$COL_RESET"
}

# mp_mariadb_create_db <database>
function mp_mariadb_create_db {
	mp_sql <<EOF
CREATE DATABASE IF NOT EXISTS $(sql_ident "$1");
EOF
}

# mp_mariadb_grant <user> <host> <password> <database>
# Create (or update) a user that may only connect from <host> and only has
# access to <database>.
function mp_mariadb_grant {
	local user host
	user=$(sql_quote "$1")
	host=$(sql_quote "$2")
	mp_sql <<EOF
CREATE USER IF NOT EXISTS ${user}@${host} IDENTIFIED BY $(sql_quote "$3");
ALTER USER ${user}@${host} IDENTIFIED BY $(sql_quote "$3");
GRANT ALL PRIVILEGES ON $(sql_ident "$4").* TO ${user}@${host};
FLUSH PRIVILEGES;
EOF
}

# Import the YiiMP schema into an empty database.
function mp_import_yiimp_db {
	local sql_dir="$STORAGE_ROOT/yiimp/yiimp_setup/yiimp/sql"
	if [ -n "$(mp_sql -N -e 'SHOW TABLES' "$YiiMPDBName" | head -n 1)" ]; then
		echo -e "$YELLOW Database ${YiiMPDBName} already has tables, skipping the import.$COL_RESET"
		return 0
	fi
	echo -e " Importing the YiiMP database...$COL_RESET"
	if ! zcat "$sql_dir/2019-11-10-yiimp.sql.gz" | mp_sql "$YiiMPDBName"; then
		echo -e "$RED Importing the YiiMP database failed.$COL_RESET"
		exit 1
	fi
	mp_sql --force "$YiiMPDBName" < "$sql_dir/2018-09-22-workers.sql" || true
	echo -e "$GREEN Done...$COL_RESET"
}

# mp_mariadb_configure <bind address>
# Tune MariaDB for YiiMP and only listen on the given (private) address.
function mp_mariadb_configure {
	local bind=$1
	echo -e " Configuring MariaDB...$COL_RESET"
	sudo tee /etc/mysql/mariadb.conf.d/60-yiimp.cnf > /dev/null <<EOF
# Created by the YiiMP multi server installer.
[mysqld]
bind-address            = ${bind}
max_connections         = 800
thread_cache_size       = 512
tmp_table_size          = 128M
max_heap_table_size     = 128M
wait_timeout            = 60
max_allowed_packet      = 64M
EOF
	# With WireGuard the private address only exists once wg0 is up, so
	# start MariaDB after it.
	if [[ "${wireguard:-false}" == "true" ]]; then
		sudo mkdir -p /etc/systemd/system/mariadb.service.d
		sudo tee /etc/systemd/system/mariadb.service.d/10-wireguard.conf > /dev/null <<'EOF'
[Unit]
Wants=wg-quick@wg0.service
After=wg-quick@wg0.service
EOF
		sudo systemctl daemon-reload
	fi
	restart_service mariadb
	echo -e "$GREEN Done...$COL_RESET"
}

# mp_write_my_cnf_section <file> <section> <user> <password> <database> <host>
function mp_write_my_cnf_section {
	printf '[%s]\nuser=%s\npassword=%s\ndatabase=%s\nhost=%s\n' \
		"$2" "$3" "$(mycnf_quote "$4")" "$5" "$6" | sudo tee -a "$1" > /dev/null
}

# mp_new_my_cnf <file>: create an empty 0600 credentials file.
function mp_new_my_cnf {
	sudo install -m 0600 -o "$(id -un)" -g "$(id -gn)" /dev/null "$1"
}
