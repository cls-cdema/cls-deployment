#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source ${SCRIPT_DIR}/../.env
cd ./
FILENAME=${db}_$(date +backup_%H-%M-%d-%m-%Y);
backups=${SCRIPT_DIR}/backups
mkdir -p ${backups}
cd /tmp;
export MYSQL_PWD=${pass};
mysqldump -u${user} --no-tablespaces --databases ${db} > "${FILENAME}.sql"
gzip -9  "${FILENAME}.sql"

mv "/tmp/${FILENAME}.sql.gz" ${backups}
cd /var/www/;
tar -czf ${backups}/files_${FILENAME}.tar.gz ./${domain}/public/upload/srf ./${domain}/public/upload/location
