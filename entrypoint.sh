#!/usr/bin/env bash
set -e

echo "⏳ Aguardando MariaDB..."

until mysqladmin ping -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" --silent; do
  sleep 2
done

echo "✅ MariaDB disponível"

cd /app/public

# Garantir permissões para o usuário www-data
chown -R www-data:www-data /app/public
chmod -R 755 /app/public

if [ ! -f wp-config.php ]; then
  echo "🚀 Instalando WordPress"

  wp core download --allow-root --quiet

  wp config create --allow-root \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
    --dbpass="$DB_PASSWORD" \
    --dbhost="$DB_HOST" \
    --skip-check \
    --quiet

  wp config set --allow-root WP_HOME "$WP_HOME" --type=constant
  wp config set --allow-root WP_SITEURL "$WP_SITEURL" --type=constant

  wp core install --allow-root \
    --url="$WP_HOME" \
    --title="WordPress" \
    --admin_user=admin \
    --admin_password="$(openssl rand -base64 20)" \
    --admin_email=admin@localhost \
    --skip-email \
    --quiet
fi

echo "🚀 Iniciando FrankenPHP"
exec frankenphp run --config /etc/caddy/Caddyfile
