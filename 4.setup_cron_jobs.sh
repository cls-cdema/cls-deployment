#!/bin/bash

source .env

#echo "Database backup will be setup with following dropbox API key"
#echo ${dropbox_key}
read -p "This will add cron job to backup datbase and run regular maintanance script, Do you want to proceed? (yes/no) " yn

case $yn in 
	yes ) echo env confirmed;;
	no ) echo exiting...;
		exit;;
	* ) echo invalid response;
		exit 1;;
esac

#cd ./data
#curl "https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh" -o dropbox_uploader.sh

cd ${pwd}
#sudo chmod +x dropbox_uploader.sh
#./data/dropbox_uploader.sh
sudo chmod +x ./data/db_backup.sh
sudo crontab -l > cron_bkp
sudo echo "0 */6 * * * $(pwd)/data/db_backup.sh >/dev/null 2>&1" >> cron_bkp
sudo crontab cron_bkp
sudo rm cron_bkp

#sudo crontab -l > cron_bkp
#sudo echo "0 0 1 * * $(pwd)/1.setup_server.sh update >/dev/null 2>&1" >> cron_bkp
#sudo crontab cron_bkp
#sudo rm cron_bkp
