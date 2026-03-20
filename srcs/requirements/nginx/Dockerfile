FROM debian:12

# install nginx and openssl
# some initial setup suggested by debian: https://hub.docker.com/_/debian
RUN apt-get update -y && \
	apt-get install -y nginx openssl locales && \
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
	rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.utf8

# create the dir for the ssl certificate
RUN mkdir -p /etc/nginx/ssl

# generate the certificate
# https://www.digitalocean.com/community/tutorials/openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-out /etc/nginx/ssl/inception.crt \
	-keyout /etc/nginx/ssl/inception.key \
	-subj "/C=IT/ST=Lazio/L=Rome/O=42Roma/OU=lgaudino/CN=lgaudino.42.fr/UID=lgaudino"

# create dir for nginx
RUN mkdir -p /var/run/nginx

# copy conf file and entrypoint
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf
COPY tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443

# start nginx in foreground
CMD ["/usr/local/bin/entrypoint.sh"]