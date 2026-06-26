# Plantilla Symfony + Docker

Plantilla reutilizable para proyectos Symfony con MariaDB, Caddy, Redis, RabbitMQ, Mercure y PHP parametrizable.

## Inicio rapido

```bash
make init
```

Tambien puedes usar:

```bash
make setup
```

El inicializador pregunta nombre del proyecto Docker, versiones, puertos, genera `.env`, construye contenedores y crea el proyecto Symfony si todavia no existe `composer.json`.

Tambien genera `AGENTS.md`, `.agents/skills/symfony-project/SKILL.md` y `.vscode/settings.json` para que el proyecto quede preparado para agentes y VS Code.

## Comandos utiles

```bash
make build
make start
make stop
make down
make restart
make vscode
make php-version
./docker/php/bin/php.sh -v
./docker/php/bin/phpcs.sh --version
./docker/php/bin/phpcbf.sh --version
docker-compose ps
```
