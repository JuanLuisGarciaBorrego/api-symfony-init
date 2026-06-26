# AGENTS.md

## Proyecto

Plantilla reutilizable para proyectos Symfony con Docker.

## Stack

- Symfony parametrizable desde `SYMFONY_VERSION`
- PHP parametrizable desde `PHP_VERSION`
- MariaDB como base de datos fija
- Caddy como servidor HTTP
- Redis, RabbitMQ y Mercure incluidos

## Comandos principales

```bash
make init
make start
make stop
make restart
make php
make composer-install
make migration-migrate
make vscode
```

## Reglas para agentes

- Usa Docker para ejecutar PHP, Composer y herramientas del proyecto.
- No instales PHP_CodeSniffer en `composer.json`; esta disponible globalmente en el contenedor PHP.
- No hardcodees nombres de contenedor ni fuerces el nombre del proyecto en comandos Docker; Docker debe tomarlo desde `COMPOSE_PROJECT_NAME` en `.env`.
- Manten MariaDB como base de datos del proyecto.
- Para formateo PHP usa `./docker/php/bin/phpcs.sh` y `./docker/php/bin/phpcbf.sh`.
- Evita tocar `vendor/`, `var/` y `node_modules/` salvo que sea imprescindible.
