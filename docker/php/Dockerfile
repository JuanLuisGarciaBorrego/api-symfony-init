ARG PHP_VERSION=8.5
FROM php:${PHP_VERSION}-cli

ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_HOME=/tmp/composer
ENV PATH="${COMPOSER_HOME}/vendor/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        acl \
        bash \
        ca-certificates \
        curl \
        ffmpeg \
        git \
        gnupg \
        unzip \
        zip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

WORKDIR /var/www/html
