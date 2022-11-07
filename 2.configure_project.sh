#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd ${SCRIPT_DIR}
source ${SCRIPT_DIR}/.env

sudo a2dissite ${domain}
sudo chown -R www-data: /var/www/
sudo apt-get install -y acl
sudo setfacl -R -m u:$USER:rwx /var/www
if [ "$1" = "" ]
then
    sudo cp ./data/000-default.conf /etc/apache2/sites-available/${domain}.conf
else
    echo "Skip domain configuration.."
fi

cd /var/www
ssh-keyscan github.com >>~/.ssh/known_hosts

Directory=/var/www/${domain}
if [ -d "$Directory" ]
then
	echo "found repo.."
    if [ "$1" = "reset" ]
    then
        echo "cleaning existing site.."
        sudo rm -R /var/www/${domain}
        git clone -b ${branch} ${repo} ${domain}
        git config --global --add safe.directory /var/www/d1.cls-cdema.org
    else
        cd ${domain}
        git stash && git pull origin ${branch}
        cd /var/www/
    fi
   
else
    git clone -b ${branch} ${repo} ${domain}
    git config --global --add safe.directory /var/www/d1.cls-cdema.org
fi

cd ${domain}

cp ./.env.example ./.env

sed -i "s/__DOMAIN__/${domain}/g" /var/www/${domain}/.env
sed -i "s/__DB__/${db}/g" /var/www/${domain}/.env
sed -i "s/__USER__/${user}/g" /var/www/${domain}/.env
sed -i "s/__PASS__/${pass}/g" /var/www/${domain}/.env

sudo sed -i "s/__DOMAIN__/${domain}/g" /etc/apache2/sites-available/${domain}.conf
sudo sed -i "s/__CONTACT__/${contact}/g" /etc/apache2/sites-available/${domain}.conf

sudo a2ensite ${domain}

echo "Reloading Web server..."
sudo systemctl reload apache2

cd /var/www/${domain}

echo "creating default folders.."
if [ -d /var/www/${domain}/public/upload ]
then
echo "upload folder exists."
else
sudo mkdir /var/www/${domain}/public/upload/import
fi
if [ -d /var/www/${domain}/public/upload/import ]
then
echo "import folder exists."
else
sudo mkdir /var/www/${domain}/public/upload/import
fi
if [ -d /var/www/${domain}/public/upload/export ]
then
echo "export folder exists."
else
sudo mkdir /var/www/${domain}/public/upload/export
fi
if [ -d /var/www/${domain}/public/temp ]
then
echo "temporary folder exists."
else
sudo mkdir /var/www/${domain}/public/temp
fi
if [ -d /var/www/${domain}/public/upload/library ]
then
echo "library folder exists."
else
sudo mkdir /var/www/${domain}/public/upload/library
fi
if [ -d /var/www/${domain}/public/upload/location ]
then
echo "location folder exists."
else
sudo mkdir /var/www/${domain}/public/upload/location
fi
if [ -d /var/www/${domain}/public/upload/srf ]
then
echo "srf folder exists."
else
sudo mkdir /var/www/${domain}/public/upload/srf
fi

echo 'setting permissions..'
sudo chown -R www-data:www-data /var/www/${domain}/
sudo chmod -R 765 /var/www/${domain}/
sudo chown -R www-data:www-data /var/www/${domain}/public/upload
sudo chmod -R 777 /var/www/${domain}/public/upload
sudo chown -R www-data:www-data /var/www/${domain}/vendor
sudo chown -R www-data:www-data /var/www/${domain}/storage
sudo setfacl -R -m u:$USER:rwx /var/www

echo 'updating Composer..'

composer update

echo 'migrating database..'
if [ "$1" = "reset" ]
 then
    php artisan migrate:refresh
    echo 'generating passport auth keys..'
    #php artisan passport:keys
    php artisan passport:install --force
    echo 'running initial queries..'
    sudo mysql ${db} < /var/www/${domain}/database/sqls/seed.sql
else 
    php artisan migrate
    if [ "$1" = "" ]
    then
        echo 'generating passport auth keys..'
        php artisan passport:install
    fi
fi