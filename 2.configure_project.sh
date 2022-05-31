#!/bin/bash

source .env
cd /var/www/${domain}

echo "createing default folders.."
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
echo 'done';
echo 'setup correct DNS in domain setting before proceeding next step'