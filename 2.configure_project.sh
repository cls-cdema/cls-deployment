#!/bin/bash

source .env
sudo chown -R www-data: /var/www/
sudo apt-get install -y acl
sudo setfacl -R -m u:$USER:rwx /var/www
sudo cp ./data/000-default.conf /etc/apache2/sites-available/${domain}.conf

cd /var/www
git clone ${repo} ${domain}
cd ${domain}
git checkout develop -b
cp ./.env.example ./.env

sed -i "s/__DOMAIN__/${domain}/g" /var/www/${domain}/.env
sed -i "s/__DB__/${db}/g" /var/www/${domain}/.env
sed -i "s/__USER__/${user}/g" /var/www/${domain}/.env
sed -i "s/__PASS__/${pass}/g" /var/www/${domain}/.env

sudo sed -i "s/__DOMAIN__/${domain}/g" /etc/apache2/sites-available/${domain}.conf
sudo sed -i "s/__CONTACT__/${contact}/g" /etc/apache2/sites-available/${domain}.conf

echo "Enabling site ${domain}..."
sudo a2ensite ${domain}

echo "Reloading Web server..."
sudo systemctl reload apache2

cd /var/www/${domain}

echo "creating default folders.."
sudo mkdir /var/www/${domain}/public/upload/import
sudo mkdir /var/www/${domain}/public/upload/export
sudo mkdir /var/www/${domain}/public/upload/library
sudo mkdir /var/www/${domain}/public/upload/location
sudo mkdir /var/www/${domain}/public/upload/srf

echo 'setting permissions..'
sudo chown -R www-data:www-data /var/www/${domain}/
sudo chmod -R 765 /var/www/${domain}/
sudo chown -R www-data:www-data /var/www/${domain}/public/upload
sudo chmod -R 777 /var/www/${domain}/public/upload
sudo chown -R www-data:www-data /var/www/${domain}/vendor
sudo chown -R www-data:www-data /var/www/${domain}/storage

echo 'updating Composer..'
composer update

echo 'migrating database..'
php artisan migrate

echo 'generating passport auth keys..'
php artisan passport:keys

echo 'running initial queries..'
sudo mysql ${db} < /var/www/${domain}/database/sqls/initial.sql
echo 'done';
echo 'setup correct DNS in domain setting before proceeding next step'