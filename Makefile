NAME = inception

DOCKER_COMPOSE = docker compose -f srcs/docker-compose.yml

all:
	@mkdir -p /home/lorenzo/data/mariadb
	@mkdir -p /home/lorenzo/data/wordpress
	$(DOCKER_COMPOSE) up --build

stop:
	$(DOCKER_COMPOSE) stop

start:
	$(DOCKER_COMPOSE) start

down:
	$(DOCKER_COMPOSE) down

clean: down
	docker system prune -a

fclean:
	$(DOCKER_COMPOSE) down -v
	sudo rm -rf /home/lorenzo/data/mariadb/*
	sudo rm -rf /home/lorenzo/data/wordpress/*
	docker system prune -af

re: fclean all

.PHONY: all stop start down clean fclean re