#!/usr/bin/env bash
set -e

echo "🔒 Configurando isolamento de cliente..."

# Create isolated directory for client
mkdir -p /mnt/clients/${CLIENT_ID}

echo "🔒 Configurando quota para cliente ${CLIENT_ID}..."
juicefs quota set ${METAURL} --path /mnt/clients/${CLIENT_ID} --capacity ${STORAGE_CAPACITY} --inodes ${STORAGE_INODES}

# If /app/public is not already linked to client directory, create symlink
if [ ! -L /app/public ]; then
  echo "🔗 Criando symlink para diretório isolado do cliente ${CLIENT_ID}"
  # Move any existing content to client directory first
  if [ -d /app/public ] && [ "$(ls -A /app/public 2>/dev/null)" ]; then
    echo "📁 Movendo conteúdo existente para /mnt/clients/${CLIENT_ID}"
    mv /app/public/* /mnt/clients/${CLIENT_ID}/ 2>/dev/null || true
  fi
  # Remove the mounted directory and create symlink
  rm -rf /app/public
  ln -s /mnt/clients/${CLIENT_ID} /app/public
fi

echo "✅ Isolamento configurado"

echo "⏳ Aguardando MariaDB..."

until mysqladmin ping -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" --silent; do
  sleep 2
done

echo "✅ MariaDB disponível"

cd /app/public
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
    --admin_email=admin@example.com \
    --skip-email \
    --quiet
fi

echo "🚀 Iniciando FrankenPHP"
exec frankenphp run --config /etc/caddy/Caddyfile
