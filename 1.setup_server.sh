#!/bin/bash

source .env

echo "Welcome to CLS Pase 1 Installer 1.0.0."
echo "This will install server and setup CLS Phase 1 Project based on following environment settings from ./env file."
echo ""
echo "Domain = ${domain}"
echo "Database = ${db}"
echo "Database User = ${user}"
echo "Admin Email = ${contact}"
echo "CLS Project Repository = ${repo}"
echo "Repository Branch = {$branch}"
echo ""
if [ "$1" = "update" ]
 then
 echo "Update mode.."
 else
read -p "Do you want to proceed? (yes/no) " yn

case $yn in 
	yes ) echo env confirmed;;
	no ) echo exiting...;
		exit;;
	* ) echo invalid response;
		exit 1;;
esac
fi

echo "Updating system.."
#sudo apt update -y
#sudo apt upgrade -y

export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
sudo -E apt-get -qy update
sudo -E apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
sudo -E apt-get -qy autoclean

sudo apt install git apache2 -y
sudo ufw allow 'Apache Full'
sudo apt install mysql-server -y
#sudo apt install php libapache2-mod-php php7.4-mysql php7.4-common php7.4-mysql php-xml php7.4-xmlrpc php7.4-curl php-gd php7.4-imagick php7.4-cli php7.4-dev php7.4-imap php7.4-mbstring php7.4-opcache php7.4-soap php7.4-zip php7.4-intl php-xml -y 
sudo apt install php libapache2-mod-php php-mysql php-common php-mysql php-xml php-xmlrpc php-curl php-gd php-imagick php-cli php-dev php-imap php-mbstring php-opcache php-soap php-zip php-intl php-xml -y 
if [ "$1" = "update" ]
 then
 echo "Configuration setting skipped for update mode"
 else
ssh-keyscan github.com >>~/.ssh/known_hosts

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
  echo ""
fi



echo 'Please proceed to next step to configure the project'
fi
#echo 'update .env file before proceeding to next step.'