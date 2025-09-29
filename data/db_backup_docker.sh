#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source ${SCRIPT_DIR}/../.env

FILENAME=${db}_$(date +backup_%H-%M-%d-%m-%Y)
backups=${SCRIPT_DIR}/backups
mkdir -p ${backups}

# Backup Database
export MYSQL_PWD=${pass}
mysqldump -h${db_host} -u${user} --no-tablespaces --databases ${db} > "/tmp/${FILENAME}.sql"
gzip -9 "/tmp/${FILENAME}.sql"
mv "/tmp/${FILENAME}.sql.gz" ${backups}

# Backup Files
PROJECT_DIR=$(dirname "${SCRIPT_DIR}")/cls
cd ${PROJECT_DIR}/public/upload
tar -czf ${backups}/files_${FILENAME}.tar.gz -C srf location
