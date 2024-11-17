MAKEFLAGS += --no-print-directory

.PHONY: all install help list test debug clean vault mariadb ubuntu debian network

UNAME := $(shell uname -s)
SCRIPT_DIR := $(shell sed "s@$$HOME@~@" <<<$$(pwd))

YOLO_DATA_TARGET_DEFAULT = ~/Data
YOLO_VAULT_SERVER_DEV_DEFAULT = y

YOLO_DEBIAN_GIT_CONFIG_FULL_NAME = $(shell bash -c '[ ! -f ./yolo/debian.env ] || . ./yolo/debian.env; value="$${GIT_CONFIG_FULL_NAME:-"Andrew Haller"}"; read -e -i "$$value" -p "$$(printf "\033[32;1m%s\033[0m %s \033[2m[%s]\033[0m" "?" "Full Name" "$$value"): " input && [ -n "$$input" ] || input="$$value"; echo "$$input"')
YOLO_DEBIAN_GIT_CONFIG_EMAIL = $(shell bash -c '[ ! -f ./yolo/debian.env ] || . ./yolo/debian.env; domain="$${YOLO_DOMAIN:-example.com}"; value="$${GIT_CONFIG_EMAIL:-andrew.haller@$${domain}}"; read -e -i "$$value" -p "$$(printf "\033[32;1m%s\033[0m %s \033[2m[%s]\033[0m" "?" "Email" "$$value"): " input && [ -n "$$input" ] || input="$$value"; echo "$$input"')
YOLO_DEBIAN_GIT_CONFIG_USERNAME = $(shell bash -c '[ ! -f ./yolo/debian.env ] || . ./yolo/debian.env; value="$${GIT_CONFIG_USERNAME:-andrewhaller}"; read -e -i "$$value" -p "$$(printf "\033[32;1m%s\033[0m %s \033[2m[%s]\033[0m" "?" "GitHub Username" "$$value"): " input && [ -n "$$input" ] || input="$$value"; echo "$$input"')
YOLO_DEBIAN_DATA_TARGET = $(shell bash -c '[ ! -f ./yolo/debian.env ] || . ./yolo/debian.env; value="$${YOLO_DATA_TARGET:-$(YOLO_DATA_TARGET_DEFAULT)}"; read -e -i $$value -p "$$(printf "\033[32;1m%s\033[0m %s \033[2m[%s]\033[0m" "?" "Data mount target" "$$value"): " input && [ -n "$$input" ] || input="$$value"; echo "$$input"')

YOLO_UBUNTU_GIT_CONFIG_FULL_NAME = $(shell bash -c '[ ! -f ./yolo/ubuntu.env ] || . ./yolo/ubuntu.env; value="$${GIT_CONFIG_FULL_NAME:-"Andrew Haller"}"; read -e -i "$$value" -p "$$(printf "\033[32;1m%s\033[0m %s \033[2m[%s]\033[0m" "?" "Full Name" "$$value"): " input && [ -n "$$input" ] || input="$$value"; echo "$$input"')
YOLO_UBUNTU_GIT_CONFIG_EMAIL = $(shell bash -c '[ ! -f ./yolo/ubuntu.env ] || . ./yolo/ubuntu.env; domain="$${YOLO_DOMAIN:-example.com}"; value="$${GIT_CONFIG_EMAIL:-andrew.haller@$${domain}}"; read -e -i "$$value" -p "$$(printf "\033[32;1m%s\033[0m %s \033[2m[%s]\033[0m" "?" "Email" "$$value"): " input && [ -n "$$input" ] || input="$$value"; echo "$$input"')
YOLO_UBUNTU_GIT_CONFIG_USERNAME = $(shell bash -c '[ ! -f ./yolo/ubuntu.env ] || . ./yolo/ubuntu.env; value="$${GIT_CONFIG_USERNAME:-andrewhaller}"; read -e -i "$$value" -p "$$(printf "\033[32;1m%s\033[0m %s \033[2m[%s]\033[0m" "?" "GitHub Username" "$$value"): " input && [ -n "$$input" ] || input="$$value"; echo "$$input"')
YOLO_UBUNTU_DATA_TARGET = $(shell bash -c '[ ! -f ./yolo/ubuntu.env ] || . ./yolo/ubuntu.env; value="$${YOLO_DATA_TARGET:-$(YOLO_DATA_TARGET_DEFAULT)}"; read -e -i $$value -p "$$(printf "\033[32;1m%s\033[0m %s \033[2m[%s]\033[0m" "?" "Data mount target" "$$value"): " input && [ -n "$$input" ] || input="$$value"; echo "$$input"')

YOLO_VAULT_SERVER_DEV = $(shell bash -c 'value=$(YOLO_VAULT_SERVER_DEV_DEFAULT); read -n 1 -r -p "YOLO_VAULT_SERVER_DEV: [Y/n] " input && [ -n "$$input" ] || input="$$value"; [ "$$input" = "y" -o "$$input" = "Y" ] && echo "dev" || echo')

all: $(TARGETS)
	@printf "\033[1m%s\033[0m\n" "Please specify additional targets"

.PHONY: help
help: ## Show this help.
	@echo "Please use \`make <target>' where <target> is one of"
	@grep '^[a-zA-Z]' $(MAKEFILE_LIST) | \
    sort | \
    awk -F ':.*?## ' 'NF==2 {printf "\033[36m  %-26s\033[0m %s\n", $$1, $$2}'

.list-targets:
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort

.PHONY: list
list: ## List public targets
	@LC_ALL=C $(MAKE) .list-targets | grep -E -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs -n3 printf "%-26s%-26s%-26s%s\n"

debug: $(TARGETS) ## Debug
	@printf "\033[4mShowing Vars\033[0m\n%s\t= %s\n" "SCRIPT_DIR" "$(SCRIPT_DIR)"

install: $(TARGETS) ## Install
	@printf "\nTo containerfy:\n\trun: \`\033[1m%s\033[0m\`\n" "make [install] <target> -C $(SCRIPT_DIR)"
	@LC_ALL=C $(MAKE) .network_msg

.network_msg:
	@printf "\nTo easily connect to a new or existing bridge network: \n\t1) run \`\033[1m%s\033[0m\`\n\t2) restart your container (after it's been initialized)\n" "make network -C $(SCRIPT_DIR)"
	@echo

.network: install
	@printf "\033[7;1m\t\t\tContainerfy %s\t\t\t\033[0m\n" "bridge network"

network: .network ## Create docker network
	@sh bin/network.sh

.containerfy_ubuntu: install
	@printf "\033[7;1m\t\t\tContainerfy %s\t\t\t\033[0m\n" "ubuntu"

ubuntu: .containerfy_ubuntu ## Ubuntu container
	@bash -c 'conrol_c() { LC_ALL=C $(MAKE) .network_msg; exit 0; }; trap conrol_c SIGINT SIGTERM SIGHUP; [ ! -f ./yolo/ubuntu.env ] || . ./yolo/ubuntu.env; GIT_CONFIG_FULL_NAME="$(YOLO_UBUNTU_GIT_CONFIG_FULL_NAME)" GIT_CONFIG_EMAIL="$(YOLO_UBUNTU_GIT_CONFIG_EMAIL)" GIT_CONFIG_USERNAME="$(YOLO_UBUNTU_GIT_CONFIG_USERNAME)" YOLO_DATA_TARGET=$(YOLO_UBUNTU_DATA_TARGET) sh $(SCRIPT_DIR)/yolo/yolo.sh'

.containerfy_debian: install
	@printf "\033[7;1m\t\t\tContainerfy %s\t\t\t\033[0m\n" "debian"

debian: .containerfy_debian ## Debian container
	@bash -c 'conrol_c() { LC_ALL=C $(MAKE) .network_msg; exit 0; }; trap conrol_c SIGINT SIGTERM SIGHUP; [ ! -f ./yolo/debian.env ] || . ./yolo/debian.env; GIT_CONFIG_FULL_NAME="$(YOLO_DEBIAN_GIT_CONFIG_FULL_NAME)" GIT_CONFIG_EMAIL="$(YOLO_DEBIAN_GIT_CONFIG_EMAIL)" GIT_CONFIG_USERNAME="$(YOLO_DEBIAN_GIT_CONFIG_USERNAME)" YOLO_DATA_TARGET=$(YOLO_DEBIAN_DATA_TARGET) sh $(SCRIPT_DIR)/yolo/yolo.debian.sh'

.vault-dev:
	@printf "\033[7;1m\t\t\tContainerfy %s\t\t\t\033[0m\n" "vault-server --dev"

vault-dev: .vault-dev
	@sh $(SCRIPT_DIR)/vault/vault.sh dev

.vault:
	@printf "\033[7;1mContainerfy %s\033[0m\n" "vault-server"

vault: .vault ## Vault container
	@sh $(SCRIPT_DIR)/vault/vault.sh $(YOLO_VAULT_SERVER_DEV)

.mariadb:
	@printf "\033[7;1m\t\t\tContainerfy %s\t\t\t\033[0m\n" "mariadb"

mariadb: .mariadb ## Mariadb container
	@sh $(SCRIPT_DIR)/mariadb/mariadb.sh

# TODO: make 'yolo' dynamically reflective of PROFILE_NAME
clean-ubuntu: clean-ubuntu-entrypoint ## Clean ubuntu
	@rm -f $(SCRIPT_DIR)/yolo/yolo-ubuntu-*.log
	@docker rm -f $$(docker ps -a -q --filter name=yolo-ubuntu-*)

clean-ubuntu-entrypoint: ## Clean ubuntu entrypoint
	@rm -f $(SCRIPT_DIR)/yolo/yolo.docker-entrypoint.ubuntu.*.sh

clean-debian: clean-debian-entrypoint ## Clean debian
	@rm -f $(SCRIPT_DIR)/yolo/yolo-debian-*.log
	@docker rm -f $$(docker ps -a -q --filter name=yolo-debian-*)

clean-debian-entrypoint: ## Clean debian entrypoint
	@rm -f $(SCRIPT_DIR)/yolo/yolo.docker-entrypoint.debian.*.sh

clean: ## Prune images and volumes
	@docker volume prune
	@docker image prune -a

fix-permissions: ## Sets .dockermount group ownership to 'staff'; Sets .dockermount/yolo/<ubuntu|debian> group permission to write
	@sudo chown :staff "$(shell realpath $(SCRIPT_DIR)/.dockermount)"
	@find .dockermount -type d ! -name '.*' -mindepth 2 -maxdepth 2 -exec sudo chmod g+w {} \;
