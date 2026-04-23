#!/bin/bash
# .devcontainer/setup.sh
# Runs automatically on first Codespaces launch.
# Sets up Nginx, WordPress, WooCommerce, and all plugins from scratch.
# Safe to re-run — checks before overwriting.

set -e
echo "==> UAE Dropshipping Store — Codespaces Setup"

# ── 1. Install system dependencies ──────────────────────────────────────────
echo "==> Installing system packages..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
  nginx \
  php8.2-fpm \
  php8.2-mysql \
  php8.2-curl \
  php8.2-gd \
  php8.2-mbstring \
  php8.2-xml \
  php8.2-zip \
  php8.2-intl \
  php8.2-imagick \
  unzip \
  curl \
  git

# ── 2. Install WP-CLI ───────────────────────────────────────────────────────
if ! command -v wp &> /dev/null; then
  echo "==> Installing WP-CLI..."
  curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x wp-cli.phar
  sudo mv wp-cli.phar /usr/local/bin/wp
fi

# ── 3. Install Claude Code CLI ──────────────────────────────────────────────
if ! command -v claude &> /dev/null; then
  echo "==> Installing Claude Code CLI..."
  npm install -g @anthropic-ai/claude-code
fi

# ── 4. Configure MySQL ──────────────────────────────────────────────────────
echo "==> Configuring MySQL..."
sudo service mysql start
sudo mysql -e "CREATE DATABASE IF NOT EXISTS wp_store CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'wp_user'@'localhost' IDENTIFIED BY 'wp_dev_password';"
sudo mysql -e "GRANT ALL PRIVILEGES ON wp_store.* TO 'wp_user'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# ── 5. Configure Nginx ──────────────────────────────────────────────────────
echo "==> Configuring Nginx..."
sudo tee /etc/nginx/sites-available/store << 'NGINX'
server {
    listen 8080;
    server_name localhost;
    root /workspace/public;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires max;
        log_not_found off;
    }

    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt  { log_not_found off; access_log off; allow all; }
}
NGINX

sudo ln -sf /etc/nginx/sites-available/store /etc/nginx/sites-enabled/store
sudo rm -f /etc/nginx/sites-enabled/default
sudo service nginx start
sudo service php8.2-fpm start

# ── 6. Download and configure WordPress ─────────────────────────────────────
if [ ! -f /workspace/public/wp-config.php ]; then
  echo "==> Downloading WordPress..."
  mkdir -p /workspace/public
  wp core download --path=/workspace/public --locale=en_US --allow-root

  echo "==> Creating wp-config.php..."
  wp config create \
    --path=/workspace/public \
    --dbname=wp_store \
    --dbuser=wp_user \
    --dbpass=wp_dev_password \
    --dbhost=localhost \
    --dbprefix=wds_ \
    --allow-root

  echo "==> Installing WordPress..."
  wp core install \
    --path=/workspace/public \
    --url="http://localhost:8080" \
    --title="UAE Dropshipping Store" \
    --admin_user=admin \
    --admin_password=admin123 \
    --admin_email=admin@example.com \
    --allow-root
fi

# ── 7. Install WooCommerce + essential plugins ───────────────────────────────
echo "==> Installing WooCommerce and plugins..."
wp plugin install woocommerce --activate --path=/workspace/public --allow-root
wp plugin install astra-sites --path=/workspace/public --allow-root
wp plugin install all-in-one-seo-pack --activate --path=/workspace/public --allow-root
wp plugin install contact-form-7 --activate --path=/workspace/public --allow-root
wp plugin install wordfence --path=/workspace/public --allow-root
wp plugin install woocommerce-pdf-invoices-packing-slips --activate --path=/workspace/public --allow-root
wp plugin install mailchimp-for-woocommerce --path=/workspace/public --allow-root

# ── 8. Install and activate Astra theme ─────────────────────────────────────
echo "==> Installing Astra theme..."
wp theme install astra --activate --path=/workspace/public --allow-root

# Create Astra child theme if not already tracked
if [ ! -d /workspace/public/wp-content/themes/astra-child ]; then
  mkdir -p /workspace/public/wp-content/themes/astra-child
  cat > /workspace/public/wp-content/themes/astra-child/style.css << 'CSS'
/*
Theme Name: Astra Child (UAE Store)
Template: astra
Version: 1.0.0
Description: Child theme for UAE Dropshipping Store
*/
CSS
  cat > /workspace/public/wp-content/themes/astra-child/functions.php << 'PHP'
<?php
// Enqueue parent theme styles
add_action('wp_enqueue_scripts', function() {
    wp_enqueue_style('astra-parent', get_template_directory_uri() . '/style.css');
    wp_enqueue_style('astra-child', get_stylesheet_uri(), ['astra-parent']);
});
PHP
  wp theme activate astra-child --path=/workspace/public --allow-root
fi

# ── 9. Configure WooCommerce UAE settings ───────────────────────────────────
echo "==> Configuring WooCommerce for UAE..."
wp option update woocommerce_store_address "Dubai, United Arab Emirates" --path=/workspace/public --allow-root
wp option update woocommerce_default_country "AE" --path=/workspace/public --allow-root
wp option update woocommerce_currency "AED" --path=/workspace/public --allow-root
wp option update woocommerce_currency_pos "left" --path=/workspace/public --allow-root
wp option update woocommerce_price_thousand_sep "," --path=/workspace/public --allow-root
wp option update woocommerce_price_decimal_sep "." --path=/workspace/public --allow-root
wp option update woocommerce_price_num_decimals 2 --path=/workspace/public --allow-root
wp option update woocommerce_enable_cod "yes" --path=/workspace/public --allow-root

# UAE VAT 5%
wp option update woocommerce_calc_taxes "yes" --path=/workspace/public --allow-root
wp option update woocommerce_tax_display_shop "incl" --path=/workspace/public --allow-root

# ── 10. Install Python dependencies ─────────────────────────────────────────
echo "==> Installing Python packages..."
pip install -q anthropic requests python-dotenv mysql-connector-python schedule

# ── 11. Create .env.example if not present ──────────────────────────────────
if [ ! -f /workspace/.env.example ]; then
  cp /workspace/.env.example.template /workspace/.env.example 2>/dev/null || true
fi

# Copy .env.example to .env for local dev if .env doesn't exist
if [ ! -f /workspace/.env ]; then
  cat > /workspace/.env << 'ENV'
# ── Site ──────────────────────────────────────────────
SITE_URL=http://localhost:8080
SITE_NAME=UAE Dropshipping Store
ADMIN_EMAIL=admin@example.com

# ── Database (Codespaces local) ───────────────────────
DB_NAME=wp_store
DB_USER=wp_user
DB_PASSWORD=wp_dev_password
DB_HOST=localhost

# ── Claude API ────────────────────────────────────────
ANTHROPIC_API_KEY=

# ── PayTabs (leave blank until you have credentials) ──
PAYTABS_PROFILE_ID=
PAYTABS_SERVER_KEY=
PAYTABS_REGION=UAE

# ── Arabia Dropship ───────────────────────────────────
ARABIA_DROPSHIP_API_KEY=

# ── CJ Dropshipping ───────────────────────────────────
CJ_API_KEY=
CJ_EMAIL=

# ── Telegram (order notifications) ───────────────────
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=
ENV
fi

# ── 12. Set file permissions ─────────────────────────────────────────────────
echo "==> Setting permissions..."
sudo chown -R www-data:www-data /workspace/public/wp-content
sudo chmod -R 755 /workspace/public

echo ""
echo "======================================================"
echo "  Setup complete!"
echo "  Store URL  : http://localhost:8080"
echo "  Admin URL  : http://localhost:8080/wp-admin"
echo "  Username   : admin"
echo "  Password   : admin123"
echo ""
echo "  NEXT: Add your ANTHROPIC_API_KEY to .env"
echo "        then run: claude (to start Claude Code)"
echo "======================================================"
