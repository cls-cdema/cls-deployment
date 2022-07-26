#!/bin/bash

source .env
if[ "${dropbox_key}" = ""]
then
    echo "Please set correct dropbox api key in .env file and run again."
    exit;
fi
sudo crontab -l > cron_bkp
sudo echo "0 */6 * * * $(pwd)/db_backup.sh >/dev/null 2>&1" >> cron_bkp
sudo crontab cron_bkp
sudo rm cron_bkp

sudo crontab -l > cron_bkp
sudo echo "0 0 1 * * $(pwd)/1.setup_server.sh update >/dev/null 2>&1" >> cron_bkp
sudo crontab cron_bkp
sudo rm cron_bkp
