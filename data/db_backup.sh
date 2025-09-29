SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source ${SCRIPT_DIR}/../.env
PROJECT_DIR=/var/www/${domain}
source ${PROJECT_DIR}/.env

UNAME=$(date +backup_%H-%M-%d-%m-%Y)
FILENAME=${CLS_DOMAIN}_${UNAME}
mkdir /tmp/${FILENAME}
backups=${SCRIPT_DIR}/backups
mkdir -p ${backups}

# Backup Database
#IP_HOST=$(docker inspect   -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${DB_HOST})
#echo ${IP_HOST}
export MYSQL_PWD=${DB_PASSWORD}
mysqldump -h${DB_HOST} -u${DB_USERNAME} --no-tablespaces --databases ${DB_DATABASE} > "/tmp/${FILENAME}.sql"
gzip -9 "/tmp/${FILENAME}.sql"
mv "/tmp/${FILENAME}.sql.gz" /tmp/${FILENAME}/

# Backup Files
cd ${PROJECT_DIR}/public/upload
cp ./srf /tmp/${FILENAME}/ -R
cp ./location /tmp/${FILENAME}/ -R
cd /tmp/
tar -czf ${backups}/files_${FILENAME}.tar.gz ./${FILENAME}
rm ./${FILENAME} -R