#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source ${SCRIPT_DIR}/../.env
cd /var/www/${domain}
echo "Enabling maintanance mode.."
php artisan down
echo "Cleaning directories.."
sudo rm /var/www/${domain}/public/upload/temp/* -R
sudo rm /var/www/${domain}/public/upload/export/* -R
echo "Disabling maintanance mode.."
sudo rm storage/framework/down
php artisan up

