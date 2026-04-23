#!/bin/bash
set -e
echo "==> Starting UAE Store setup..."

sudo apk update && sudo apk add --no-cache \
  nginx php83 php83-fpm php83-pdo php83-pdo_mysql php83-mysqli \
  php83-mysqlnd php83-curl php83-gd php83-mbstring php83-xml \
  php83-xmlwriter php83-simplexml php83-zip php83-intl php83-opcache \
  php83-session php83-tokenizer php83-dom php83-fileinfo php83-openssl \
  php83-phar php83-iconv php83-ctype mariadb mariadb-client \
  mariadb-openrc unzip curl nodejs npm python3 py3-pip

sudo ln -sf /usr/bin/php83 /usr/local/bin/php

curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar && sudo mv wp-cli.phar /usr/local/bin/wp

sudo mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null 2>&1
sudo mysqld_safe --datadir=/var/lib/mysql &
sleep 5

sudo mariadb << 'SQL'
CREATE DATABASE IF NOT EXISTS wp_store CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'wp_user'@'localhost' IDENTIFIED BY 'wp_dev_pass';
GRANT ALL PRIVILEGES ON wp_store.* TO 'wp_user'@'localhost';
FLUSH PRIVILEGES;
SQL

sudo mkdir -p /var/www/store
sudo chown -R $(whoami):$(whoami) /var/www/store

sudo tee /etc/nginx/http.d/store.conf << 'NGINX'
server {
    listen 8080;
    server_name localhost;
    root /var/www/store;
    index index.php index.html;
    location / { try_files $uri $uri/ /index.php?$args; }
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi.conf;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
NGINX

sudo sed -i 's|listen = /var/run/php-fpm83.sock|listen = 127.0.0.1:9000|' /etc/php83/php-fpm.d/www.conf
sudo php-fpm83
sudo nginx

php -d memory_limit=512M /usr/local/bin/wp core download --path=/var/www/store --allow-root
php -d memory_limit=512M /usr/local/bin/wp config create \
  --path=/var/www/store --dbname=wp_store --dbuser=wp_user \
  --dbpass=wp_dev_pass --dbhost=localhost --dbprefix=wds_ --allow-root
php -d memory_limit=512M /usr/local/bin/wp core install \
  --path=/var/www/store --url="http://localhost:8080" \
  --title="UAE Dropshipping Store" --admin_user=admin \
  --admin_password=admin123 --admin_email=admin@example.com --allow-root
php -d memory_limit=512M /usr/local/bin/wp plugin install woocommerce --activate --path=/var/www/store --allow-root
php -d memory_limit=512M /usr/local/bin/wp theme install astra --activate --path=/var/www/store --allow-root

echo "==> Setup complete! Store at http://localhost:8080"
echo "==> Admin: http://localhost:8080/wp-admin | admin / admin123"
