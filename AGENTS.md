# AGENTS.md

## Proyecto

Este proyecto es una aplicacion Symfony creada desde la plantilla Docker local.

## Stack

- Symfony 8.1
- PHP 8.5 en Docker
- MariaDB como base de datos fija
- Caddy como servidor HTTP
- Redis para cache/colas cuando aplique
- RabbitMQ para mensajeria
- Mercure para tiempo real

## Comandos principales

```bash
make start
make stop
make restart
make php
make composer-install
make create-database
make migration-create
make migration-migrate
make messenger
make scheduler
make vscode
```

## Reglas para agentes

- Usa Docker para ejecutar PHP, Composer y herramientas del proyecto.
- No instales PHP_CodeSniffer en `composer.json`; esta disponible globalmente en el contenedor PHP.
- No hardcodees nombres de contenedor ni fuerces el nombre del proyecto en comandos Docker; Docker debe tomarlo desde `COMPOSE_PROJECT_NAME` en `.env`.
- Manten MariaDB como base de datos del proyecto.
- Antes de cambiar configuracion Docker, revisa `compose.yaml`, `.env` y `docker/php/Dockerfile`.
- Para formateo PHP usa `./docker/php/bin/phpcs.sh` y `./docker/php/bin/phpcbf.sh`.
- Para comandos Symfony usa `docker-compose exec -T php php bin/console ...`.
- Evita tocar `vendor/`, `var/` y `node_modules/` salvo que sea imprescindible.

## Verificacion recomendada

```bash
make php-version
./docker/php/bin/phpcs.sh --version
./docker/php/bin/phpcbf.sh --version
docker-compose ps
```
