#!/bin/bash

# sourse the credentials in secrets
if [ -f /run/secrets/credentials ]; then
	source /run/secrets/credentials
else
	echo "Error: secrets not found"
	exit 1
fi

# check if wp is already initialized
if [ ! -f "/var/www/html/wp-config.php" ]; then
	echo "First execution!"

	# Downloads core WordPress files.
	wp core download --allow-root

	# create wp-config.php with db info
	wp config create \
		--dbname=${MYSQL_DATABASE} \
		--dbuser=${MYSQL_USER} \
		--dbpass=$(cat /run/secrets/db_password) \
		--dbhost=mariadb:3306 \
		--allow-root

	# install WordPress and create admin user
	wp core install \
		--url=${DOMAIN_NAME} \
		--title="Inception" \
		--admin_user=${WP_ADMIN_USER} \
		--admin_password=${WP_ADMIN_PASS} \
		--admin_email=${WP_ADMIN_EMAIL} \
		--allow-root

	# create a second user
	wp user create \
		${WP_USER} \
		${WP_USER_EMAIL} \
		--role=author \
		--user_pass=${WP_USER_PASS} \
		--allow-root

	# gives to nginx the permissions to read this files
	chown -R www-data:www-data /var/www/html
	
	echo "WordPress install completed"
else
	echo "WordPress already installed"
fi

# execute PHP-FPM in foreground
exec php-fpm8.2 -F