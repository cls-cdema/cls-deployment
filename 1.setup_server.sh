#!/bin/bash

source .env
sudo apt update -y
sudo apt upgrade -y
sudo apt install git apache2 -y
sudo ufw allow 'Apache Full'
sudo apt install mysql-server -y
#sudo apt install php libapache2-mod-php php7.4-mysql php7.4-common php7.4-mysql php-xml php7.4-xmlrpc php7.4-curl php-gd php7.4-imagick php7.4-cli php7.4-dev php7.4-imap php7.4-mbstring php7.4-opcache php7.4-soap php7.4-zip php7.4-intl php-xml -y 
sudo apt install php libapache2-mod-php php-mysql php-common php-mysql php-xml php-xmlrpc php-curl php-gd php-imagick php-cli php-dev php-imap php-mbstring php-opcache php-soap php-zip php-intl php-xml -y 
sudo a2dissite 000-default
sudo a2enmod rewrite
sudo apt install composer -y
sudo apt install python3-certbot-apache -y

sed -i "s/__DOMAIN__/${domain}/g" ./data/db.sql
sed -i "s/__DB__/${db}/g" ./data/db.sql
sed -i "s/__USER__/${user}/g" ./data/db.sql
sed -i "s/__PASS__/${pass}/g" ./data/db.sql

echo "Preparing MySQL Database and User..."
sudo mysql < ./data/db.sql


SSHKEY=~/.ssh/id_rsa.pub
if [ -f "$SSHKEY" ]; then
    echo "$SSHKEY exists."
   
else 
    echo "$SSHKEY does not exist, Please follow the screen instruction to genenrate ssh key.."
    ssh-keygen
fi
if [ -f "$SSHKEY" ]; then
   echo "Please contact admin to enable following ssh deployment key at repository ${repo}."
   echo "After setting up deployment key, you can proceed to next setp 2.configure_project."
   cat $SSHKEY
else 
fi



echo 'Please proceed to next step to configure the project'
#echo 'update .env file before proceeding to next step.'