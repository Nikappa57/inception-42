#!/bin/bash

if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "Initialize mariadb basic tables"
	mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

# check if the database exist
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
	echo "Initialize mysql tables"
	
	if [ ! -f "/run/secrets/db_password" ] || [ ! -f "/run/secrets/db_root_password" ]; then
		echo "Error: Database secrets not found"
		exit 1
	fi

	# Read secrets
	DB_PASS=$(cat /run/secrets/db_password)
	DB_ROOT_PASS=$(cat /run/secrets/db_root_password)

	echo "Creating table \`${MYSQL_DATABASE}\`, user: \`${MYSQL_USER}\`@'%'"

	# define database
	cat << EOF > /tmp/init.sql
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
FLUSH PRIVILEGES;
EOF

	echo "execute mariadb..."
	# execute in foreground, but first call init.sql
	exec mysqld_safe --init-file=/tmp/init.sql
else
	echo "Database already exist, execute mariadb..."
	# execute in foreground
	exec mysqld_safe
fi