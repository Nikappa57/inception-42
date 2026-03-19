#!/bin/bash

# check if the database exist
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "First execution"
    
    # Create base tables
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # Read secrets
    DB_PASS=$(cat /run/secrets/db_password)
    DB_ROOT_PASS=$(cat /run/secrets/db_root_password)

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