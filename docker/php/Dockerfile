FROM composer:2.7 AS vendor

WORKDIR /app

COPY app/composer.json app/composer.lock ./

RUN composer install \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --optimize-autoloader \
    --no-scripts

COPY app/ ./

RUN composer dump-autoload --optimize --no-dev

FROM node:20-alpine AS assets

WORKDIR /app

COPY app/package*.json ./

RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

COPY app/ ./

RUN npm run build

FROM php:8.2-fpm

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    curl \
    zip \
    unzip \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    default-mysql-client \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip opcache \
    && mkdir -p /etc/mysql/certs /etc/mysql/conf.d \
    && curl -fsSL https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -o /etc/mysql/certs/rds-global-bundle.pem \
    && chmod 0644 /etc/mysql/certs/rds-global-bundle.pem \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY app/ ./
COPY --from=vendor /app/vendor ./vendor
COPY --from=assets /app/public/build ./public/build
COPY docker/php/rds-ssl.cnf /etc/mysql/conf.d/rds-ssl.cnf
COPY app/.docker/php/local.ini /usr/local/etc/php/conf.d/local.ini

RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 9000
