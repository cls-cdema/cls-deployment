#!/bin/bash

source .env
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd ${SCRIPT_DIR}

read -p "This will add cron job to backup datbase and run regular maintanance script, Do you want to proceed? (yes/no) " yn

case $yn in 
        yes ) echo env confirmed;;
        no ) echo exiting...;
                exit;;
        * ) echo invalid response;
                exit 1;;
esac

echo "Setting cron jobs for database backup..."
sudo chmod +x ${SCRIPT_DIR}/data/db_backup.sh
job="0 */6 * * * ${SCRIPT_DIR}/data/db_backup.sh >/dev/null 2>&1";
#$crontab -l > cron_bkp
grep ${job} /etc/crontab || echo job >> /etc/crontab

echo "Setting cron jobs for site maintanance..."
sudo chmod +x ${SCRIPT_DIR}/data/maintanance.sh
job="0 */6 * * * ${SCRIPT_DIR}/data/maintanance.sh >/dev/null 2>&1";
#$crontab -l > cron_bkp
grep ${job} /etc/crontab || echo job >> /etc/crontab

