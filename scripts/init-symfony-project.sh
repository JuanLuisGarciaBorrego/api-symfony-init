#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

prompt() {
    local name="$1"
    local default="$2"
    local value

    read -r -p "$name [$default]: " value
    echo "${value:-$default}"
}

port_is_available() {
    local port="$1"
    python3 - "$port" <<'PY'
import socket
import sys

port = int(sys.argv[1])
s = socket.socket()
try:
    s.bind(("0.0.0.0", port))
    s.close()
    print(1)
except OSError:
    print(0)
PY
}

find_available_port() {
    local port="$1"
    local candidate="$port"

    while [ "$(port_is_available "$candidate")" != "1" ]; do
        candidate=$((candidate + 1))
    done

    echo "$candidate"
}

resolve_port() {
    local requested="$1"
    local fallback="$2"
    local candidate="$requested"

    if [ -z "$candidate" ]; then
        candidate="$fallback"
    fi

    if [ "$(port_is_available "$candidate")" = "1" ]; then
        echo "$candidate"
    else
        find_available_port "$candidate"
    fi
}

create_agents_template() {
    mkdir -p .agents/skills/symfony-project

    cat > AGENTS.md <<EOF
# AGENTS.md

## Proyecto

Este proyecto es una aplicacion Symfony creada desde la plantilla Docker local.

## Stack

- Symfony $SYMFONY_VERSION
- PHP $PHP_VERSION en Docker
- MariaDB como base de datos fija
- Caddy como servidor HTTP
- Redis para cache/colas cuando aplique
- RabbitMQ para mensajeria
- Mercure para tiempo real

## Comandos principales

\`\`\`bash
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
\`\`\`

## Reglas para agentes

- Usa Docker para ejecutar PHP, Composer y herramientas del proyecto.
- No instales PHP_CodeSniffer en \`composer.json\`; esta disponible globalmente en el contenedor PHP.
- No hardcodees nombres de contenedor ni fuerces el nombre del proyecto en comandos Docker; Docker debe tomarlo desde \`COMPOSE_PROJECT_NAME\` en \`.env\`.
- Manten MariaDB como base de datos del proyecto.
- Antes de cambiar configuracion Docker, revisa \`compose.yaml\`, \`.env\` y \`docker/php/Dockerfile\`.
- Para formateo PHP usa \`./docker/php/bin/phpcs.sh\` y \`./docker/php/bin/phpcbf.sh\`.
- Para comandos Symfony usa \`docker-compose exec -T php php bin/console ...\`.
- Evita tocar \`vendor/\`, \`var/\` y \`node_modules/\` salvo que sea imprescindible.

## Verificacion recomendada

\`\`\`bash
make php-version
./docker/php/bin/phpcs.sh --version
./docker/php/bin/phpcbf.sh --version
docker-compose ps
\`\`\`
EOF

    cat > .agents/skills/symfony-project/SKILL.md <<EOF
# Symfony Project Skill

Usa esta skill cuando trabajes en este proyecto Symfony.

## Flujo recomendado

1. Lee \`AGENTS.md\` y \`compose.yaml\` antes de tocar infraestructura.
2. Ejecuta comandos PHP dentro del contenedor \`php\`.
3. Usa MariaDB, Redis, RabbitMQ y Mercure segun la configuracion de \`.env\`.
4. Genera configuracion de VS Code con \`make vscode\` cuando cambie la version de PHP o rutas locales.

## Comandos utiles

\`\`\`bash
make start
make php
make composer-install
make migration-migrate
make vscode
\`\`\`

## Estilo

- PHP_CodeSniffer y PHPCBF se ejecutan con los wrappers de \`docker/php/bin\`.
- No anadas \`squizlabs/php_codesniffer\` al \`composer.json\` del proyecto.
- Manten los cambios pequenos y alineados con Symfony.
EOF
}

cd "$PROJECT_DIR"

COMPOSE_PROJECT_NAME="$(prompt "COMPOSE_PROJECT_NAME" "symfony_app")"
PHP_VERSION="$(prompt "PHP_VERSION" "8.5")"
SYMFONY_VERSION="$(prompt "SYMFONY_VERSION" "8.1")"
APP_PORT="$(resolve_port "$(prompt "APP_PORT" "8000")" "8000")"
MARIADB_PORT="$(resolve_port "$(prompt "MARIADB_PORT" "3333")" "3333")"
REDIS_PORT="$(resolve_port "$(prompt "REDIS_PORT" "6379")" "6379")"
RABBITMQ_PORT="$(resolve_port "$(prompt "RABBITMQ_PORT" "5672")" "5672")"
RABBITMQ_MANAGEMENT_PORT="$(resolve_port "$(prompt "RABBITMQ_MANAGEMENT_PORT" "15672")" "15672")"
MERCURE_PORT="$(resolve_port "$(prompt "MERCURE_PORT" "9090")" "9090")"

if command -v openssl >/dev/null 2>&1; then
    APP_SECRET="$(openssl rand -hex 16)"
else
    APP_SECRET="ChangeThisSymfonyAppSecret"
fi

cat > .env <<EOF
APP_ENV=dev
APP_SECRET=$APP_SECRET
COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME
APP_PORT=$APP_PORT
MARIADB_PORT=$MARIADB_PORT
REDIS_PORT=$REDIS_PORT
RABBITMQ_PORT=$RABBITMQ_PORT
RABBITMQ_MANAGEMENT_PORT=$RABBITMQ_MANAGEMENT_PORT
MERCURE_PORT=$MERCURE_PORT
PHP_VERSION=$PHP_VERSION
SYMFONY_VERSION=$SYMFONY_VERSION
DATABASE_URL="mysql://app:app@mariadb:3306/app?serverVersion=mariadb-11.4.0&charset=utf8mb4"
REDIS_URL="redis://redis:6379"
MESSENGER_TRANSPORT_DSN="amqp://guest:guest@rabbitmq:5672/%2f/messages"
MERCURE_URL="http://mercure/.well-known/mercure"
MERCURE_PUBLIC_URL="http://localhost:$MERCURE_PORT/.well-known/mercure"
MERCURE_JWT_SECRET="!ChangeThisMercureHubJWTSecretKey!"
EOF

chmod +x docker/php/bin/*.sh

docker-compose build
docker-compose up -d php mariadb redis

for i in $(seq 1 15); do
    if docker-compose ps -q php >/dev/null 2>&1 && docker inspect -f '{{.State.Running}}' "$(docker-compose ps -q php)" >/dev/null 2>&1; then
        if [ "$(docker inspect -f '{{.State.Running}}' "$(docker-compose ps -q php)")" = "true" ]; then
            break
        fi
    fi
    sleep 1
 done

if [ "${SKIP_SYMFONY_PROJECT:-0}" = "1" ]; then
    echo "SKIP_SYMFONY_PROJECT=1; se omite la creación del proyecto Symfony."
else
    if [ ! -f composer.json ]; then
        docker-compose exec -T php rm -rf /tmp/symfony_project
        docker-compose exec -T php composer create-project "symfony/skeleton:${SYMFONY_VERSION}.*" /tmp/symfony_project
        docker-compose exec -T php cp /var/www/html/.env /tmp/template_project_env
        docker-compose exec -T php bash -lc 'shopt -s dotglob && cp -a /tmp/symfony_project/* /var/www/html/'
        docker-compose exec -T php cp /tmp/template_project_env /var/www/html/.env
        docker-compose exec -T php rm -rf /tmp/symfony_project
    else
        echo "composer.json ya existe; no se pisa el proyecto Symfony."
    fi
fi

create_agents_template
make vscode

cat <<EOF

Project: $COMPOSE_PROJECT_NAME
PHP: $PHP_VERSION
Symfony: $SYMFONY_VERSION
URL local: http://localhost:$APP_PORT
EOF
