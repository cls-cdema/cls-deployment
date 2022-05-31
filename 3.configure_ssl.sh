#!/bin/bash

source .env
echo "Please setup correct DNS entry in domain setting before setting up SSL. Press any key to continute"
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