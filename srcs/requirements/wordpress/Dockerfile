

FROM debian:12

# istall PHP, mariadb client and curl
# some initial setup suggested by debian: https://hub.docker.com/_/debian
RUN apt-get update -y && \ 
	apt-get install -y \
		php8.2-fpm \
		php8.2-mysql \
		mariadb-client \
		curl \
		locales && \
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
	rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.utf8

# download wp client https://make.wordpress.org/cli/handbook/guides/installing/
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x wp-cli.phar && \
	mv wp-cli.phar /usr/local/bin/wp

# create the necessary dirs
RUN mkdir -p /run/php && \
	mkdir -p /var/www/html && \
	chown -R www-data:www-data /var/www/html

# Copy conf and script into container
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# set the work dir of wp
WORKDIR /var/www/html

# define the port used for nginx
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]