# official docker hub image: https://hub.docker.com/_/mariadb

# custom intall: https://mariadb.com/docs/server/mariadb-quickstart-guides/installing-mariadb-server-guide

FROM debian:12

# install mariadb
# some initial setup suggested by debian: https://hub.docker.com/_/debian
RUN apt-get update -y && \
    apt-get install -y mariadb-server locales && \
    rm -rf /var/lib/apt/lists/* && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG=en_US.utf8

# Create the dir defined in conf
RUN mkdir -p /run/mysqld && \
    chown -R mysql:mysql /run/mysqld && \
    chmod 777 /run/mysqld

# copy conf and entry point script into container
COPY conf/mariadb.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# define the port
EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]