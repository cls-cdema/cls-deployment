#!/bin/bash

source .env
host ${domain}
echo "Please setup above IP address as A/AAA DNS entry in domain setting before setting up SSL. Press any key to continute"
while [ true ] ; do
read -t 3 -n 1
if [ $? = 0 ] ; then
exit ;
else
echo "waiting.."
fi

echo "setting up SSL.."
sudo certbot --apache --agree-tos --redirect -m ${contact} -d ${domain}

echo "Reloading Web server..."
sudo systemctl reload apache2
echo "success"

# error in apache2 domain config
# error in a2enmod