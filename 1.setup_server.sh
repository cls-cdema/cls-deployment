#!/bin/bash

source .env
sudo apt update -y
sudo apt upgrade -y
sudo apt install git apache2 -y
sudo ufw allow 'Apache Full'
sudo apt install mysql-server -y
sudo apt install php libapache2-mod-php php7.4-mysql php7.4-common php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-curl php7.4-gd php7.4-imagick php7.4-cli php7.4-dev php7.4-imap php7.4-mbstring php7.4-opcache php7.4-soap php7.4-zip php7.4-intl -y 
sudo a2dissite 000-default
sudo apt install composer -y
sudo apt install python3-certbot-apache -y


sed -i "s/__DOMAIN__/${domain}/" ./data/db.sql
sed -i "s/__DB__/${db}/" ./data/db.sql
sed -i "s/__USER__/${user}/" ./data/db.sql
sed -i "s/__PASS__/${pass}/" ./data/db.sql

echo "Preparing MySQL Database and User..."
sudo mysql < ./data/db.sql

sudo chown -R www-data: /var/www/
sudo apt-get install -y acl
sudo setfacl -R -m u:$USER:rwx /var/www
cd /var/www
git clone ${repo} ${domain}
cd ${domain}
git checkout develop -b
cp ./.env.example ./.env

sed -i "s/__DOMAIN__/${domain}/" /var/www/${domain}/.env
sed -i "s/__DB__/${db}/" /var/www/${domain}/.env
sed -i "s/__USER__/${user}/" /var/www/${domain}/.env
sed -i "s/__PASS__/${pass}/" /var/www/${domain}/.env

sudo cp /var/www/${domain}/run/etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-available/${domain}.conf

sudo sed -i "s/__DOMAIN__/${domain}/" /etc/apache2/sites-available/${domain}.conf
sudo sed -i "s/__CONTACT__/${contact}/" /etc/apache2/sites-available/${domain}.conf

echo "Enabling site ${domain}..."
sudo a2ensite ${domain}

echo "Reloading Web server..."
sudo systemctl reload apache2

echo 'Please proceed to next step to configure the project'
#echo 'update .env file before proceeding to next step.'