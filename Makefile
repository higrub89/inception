# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: rhiguita <rhiguita@student.42madrid.com>    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/07/29 14:00:00 by rhiguita          #+#    #+#              #
#    Updated: 2026/07/29 14:00:00 by rhiguita         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

NAME        = inception
COMPOSE     = srcs/docker-compose.yml

# Load INCEPTION_USER from .env so DATA_PATH matches the docker-compose bind mounts
INCEPTION_USER := $(shell grep '^INCEPTION_USER=' srcs/.env | cut -d'=' -f2)
DATA_PATH   = /home/$(INCEPTION_USER)/data

all: up

init_dirs:
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb

up: init_dirs
	@docker-compose -f $(COMPOSE) up -d --build

down:
	@docker-compose -f $(COMPOSE) down

start:
	@docker-compose -f $(COMPOSE) start

stop:
	@docker-compose -f $(COMPOSE) stop

status:
	@docker-compose -f $(COMPOSE) ps

logs:
	@docker-compose -f $(COMPOSE) logs -f

clean: down

fclean:
	@docker-compose -f $(COMPOSE) down -v --rmi all
	@sudo rm -rf $(DATA_PATH)

re: fclean all

.PHONY: all init_dirs up down start stop status logs clean fclean re
