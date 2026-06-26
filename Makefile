SHELL := /bin/bash

.PHONY: help setup init init-test build start stop down restart php composer-install create-database migration-create migration-migrate messenger scheduler mercure-status mercure-open phpcs phpcbf php-version vscode

help:
	@echo "Comandos disponibles:"
	@echo "  make init               Inicializa un proyecto Symfony nuevo desde la plantilla"
	@echo "  make init-test          Prueba el stack Docker sin crear el proyecto Symfony"
	@echo "  make setup              Alias de make init"
	@echo "  make build              Construye los contenedores"
	@echo "  make start              Levanta el stack Docker"
	@echo "  make stop               Para el stack Docker"
	@echo "  make down               Para y elimina los contenedores"
	@echo "  make restart            Reinicia el stack Docker"
	@echo "  make php                Abre una shell dentro del contenedor PHP"
	@echo "  make composer-install   Instala dependencias Composer"
	@echo "  make create-database    Crea la base de datos Symfony"
	@echo "  make migration-create   Crea una migracion Doctrine"
	@echo "  make migration-migrate  Ejecuta migraciones Doctrine"
	@echo "  make messenger          Consume mensajes Symfony Messenger"
	@echo "  make scheduler          Ejecuta Symfony Scheduler"
	@echo "  make mercure-status     Muestra estado del contenedor Mercure"
	@echo "  make mercure-open       Muestra URL local de Mercure"
	@echo "  make phpcs              Ejecuta PHP_CodeSniffer"
	@echo "  make phpcbf             Ejecuta PHP_CodeSniffer fixer"
	@echo "  make php-version        Muestra version PHP del contenedor"
	@echo "  make vscode             Genera configuracion VS Code del proyecto"

setup: init

init:
	@bash scripts/init-symfony-project.sh

init-test:
	@SKIP_SYMFONY_PROJECT=1 bash scripts/init-symfony-project.sh

build:
	@docker-compose build

start:
	@docker-compose up -d

stop:
	@docker-compose stop

down:
	@docker-compose down

restart: stop start

php:
	@docker-compose exec php bash

composer-install:
	@docker-compose exec -T php composer install

create-database:
	@docker-compose exec -T php php bin/console doctrine:database:create --if-not-exists

migration-create:
	@docker-compose exec -T php php bin/console make:migration

migration-migrate:
	@docker-compose exec -T php php bin/console doctrine:migrations:migrate --no-interaction

messenger:
	@docker-compose exec php php bin/console messenger:consume async -vv

scheduler:
	@docker-compose exec php php bin/console scheduler:consume default -vv

mercure-status:
	@docker-compose ps mercure

mercure-open:
	@echo "Mercure: http://localhost:$$(grep '^MERCURE_PORT=' .env 2>/dev/null | cut -d '=' -f2 || echo 9090)/.well-known/mercure/ui/"

phpcs:
	@docker-compose exec -T php phpcs

phpcbf:
	@docker-compose exec -T php phpcbf

php-version:
	@docker-compose exec -T php php -v

vscode:
	@docker-compose up -d php
	@mkdir -p .vscode
	@chmod +x docker/php/bin/*.sh
	@PHP_VERSION="$$(docker-compose exec -T php php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION.".0";')"; \
	PROJECT_DIR="$$(pwd)"; \
	printf '%s\n' \
	'{' \
	'  "files.exclude": {' \
	'    "**/var": true' \
	'  },' \
	'  "search.exclude": {' \
	'    "**/vendor": true,' \
	'    "**/var": true,' \
	'    "**/node_modules": true' \
	'  },' \
	'  "files.watcherExclude": {' \
	'    "**/vendor/**": true,' \
	'    "**/var/**": true,' \
	'    "**/node_modules/**": true' \
	'  },' \
	'  "php.validate.enable": false,' \
	"  \"intelephense.environment.phpVersion\": \"$$PHP_VERSION\"," \
	"  \"phpsab.executablePathCS\": \"$$PROJECT_DIR/docker/php/bin/phpcs.sh\"," \
	"  \"phpsab.executablePathCBF\": \"$$PROJECT_DIR/docker/php/bin/phpcbf.sh\"," \
	'  "workbench.iconTheme": "material-icon-theme",' \
	'  "editor.fontFamily": "JetBrains Mono, Fira Code, Menlo, Monaco, '\''Courier New'\'', monospace",' \
	'  "editor.fontLigatures": true,' \
	'  "editor.formatOnSave": true' \
	'}' > .vscode/settings.json
	@printf '%s\n' \
	'{' \
	'  "recommendations": [' \
	'    "bmewburn.vscode-intelephense-client",' \
	'    "junstyle.php-cs-fixer",' \
	'    "valeryanm.vscode-phpsab",' \
	'    "xdebug.php-debug",' \
	'    "whatwedo.twig",' \
	'    "TheNouillet.symfony-vscode",' \
	'    "ms-azuretools.vscode-docker",' \
	'    "pkief.material-icon-theme",' \
	'    "eamodio.gitlens",' \
	'    "editorconfig.editorconfig",' \
	'    "dbaeumer.vscode-eslint",' \
	'    "esbenp.prettier-vscode"' \
	'  ]' \
	'}' > .vscode/extensions.json
	@if command -v code >/dev/null 2>&1; then \
		while read extension; do \
			if [ -n "$$extension" ] && case "$$extension" in \#*) false;; *) true;; esac; then \
				code --install-extension "$$extension"; \
			fi; \
		done < vscode/extensions.txt; \
	else \
		echo "No encuentro el comando 'code'. En VS Code ejecuta: Shell Command: Install 'code' command in PATH"; \
	fi
