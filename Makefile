# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: rhiguita <rhiguita@student.42madrid.com>    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/07/29 14:00:00 by rhiguita          #+#    #+#              #
#    Updated: 2026/08/23 18:48:38 by rhiguita         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

NAME        := inception
COMPOSE     := srcs/docker-compose.yml

# Load INCEPTION_USER from srcs/.env with safe fallback
INCEPTION_USER ?= $(shell grep -E '^INCEPTION_USER=' srcs/.env 2>/dev/null | cut -d'=' -f2)
ifeq ($(strip $(INCEPTION_USER)),)
INCEPTION_USER := rhiguita
endif
DATA_PATH   := /home/$(INCEPTION_USER)/data

all: up

secrets:
	@mkdir -p secrets
	@if [ ! -f secrets/db_password.txt ]; then echo "inception_db_pass_2026" > secrets/db_password.txt; fi
	@if [ ! -f secrets/db_root_password.txt ]; then echo "inception_root_pass_2026" > secrets/db_root_password.txt; fi
	@if [ ! -f secrets/wp_admin_password.txt ]; then echo "inception_admin_pass_2026" > secrets/wp_admin_password.txt; fi
	@chmod 600 secrets/*.txt 2>/dev/null || true

init_dirs:
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb

up: init_dirs
	@docker compose -f $(COMPOSE) up -d --build

down:
	@docker compose -f $(COMPOSE) down

start:
	@docker compose -f $(COMPOSE) start

stop:
	@docker compose -f $(COMPOSE) stop

status:
	@docker compose -f $(COMPOSE) ps

logs:
	@docker compose -f $(COMPOSE) logs -f

clean: down

fclean:
	@docker compose -f $(COMPOSE) down -v --rmi all
	@if [ -n "$(INCEPTION_USER)" ] && [ "$(DATA_PATH)" != "/home//data" ] && [ -d "$(DATA_PATH)" ]; then \
		sudo rm -rf $(DATA_PATH); \
	fi

re: fclean all

.PHONY: all secrets init_dirs up down start stop status logs clean fclean re

