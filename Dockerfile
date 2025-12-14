FROM dunglas/frankenphp:1-php8.4-bookworm

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    unzip \
    tar \
    git \
    openssl \
    mariadb-client \
    libzip-dev \
    libonig-dev \
    libicu-dev \
    libmagickwand-dev \
    imagemagick \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libwebp-dev \
    libxml2-dev \
    g++ \
    make \
    autoconf \
    pkg-config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN install-php-extensions \
    pdo_mysql \
    mysqli \
    exif \
    gd \
    intl \
    zip \
    opcache \
    imagick \
    redis

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# WP-CLI
RUN curl -o /usr/local/bin/wp \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp


WORKDIR /app/public


COPY php.ini /usr/local/etc/php/php.ini
COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER www-data

ENTRYPOINT ["/entrypoint.sh"]
