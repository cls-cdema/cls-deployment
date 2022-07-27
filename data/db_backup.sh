#!/bin/bash

source .env
DROPBOX='/CLS_Database_Backups/'
FILENAME=${db}_$(date +backup_%H-%M-%d-%m-%Y.tar.gz);
backups=$(pwd)/backups
mkdir -p ${backups}
cd /tmp;
export MYSQL_PWD=${pass};
mysqldump -u${user} --no-tablespaces --databases ${db} > "${db}.sql"
tar czf ${FILENAME} "${DATABSE1}.sql" "${DATABSE2}.sql" "${DATABSE3}.sql"
mv /tmp/$FILENAME ${backups}

#curl -s --output -X POST https://content.dropboxapi.com/2/files/upload \
#    --header "Authorization: Bearer ${dropbox_key}" \
#    --header "Dropbox-API-Arg: {\"path\": \"${DROPBOX}${FILENAME}\"}" \
#    --header "Content-Type: application/octet-stream" \
#    --data-binary @${FILENAME}
