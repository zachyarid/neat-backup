#!/bin/sh

#backup folder within the server where backup files are stored
BAK_DEST=~/backup

#database credentials
DB_USERNAME=""
DB_PASSWORD=""

#folders for backup, can be comma separated for multiple folders
BAK_SOURCES=""

#number of days to keep archives
KEEP_DAYS=7

#script variables
BAK_DATE=`date +%F`
BAK_DATETIME=`date +%F-%H%M`
BAK_FOLDER=${BAK_DEST}/${BAK_DATE}
BAK_DB=${BAK_FOLDER}/db-${BAK_DATETIME}

#CREATE folder where backup database is to be place
echo 'Creating database back up ' ${BAK_FOLDER}
mkdir ${BAK_FOLDER}

#PERFORM mySQL Database DUMP
databases=`mysql -u ${DB_USERNAME} -p${DB_PASSWORD} -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`

for db in $databases; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]] ; then
        echo "Dumping database: $db"
        mysqldump -u ${DB_USERNAME} -p${DB_PASSWORD} --databases $db > $db.sql
    fi
done

echo 'Creating archive file ' ${BAK_DB}'.tar.gz '
tar czPf ${BAK_DB}.tar.gz *.sql

# cleanup .sql files
rm *.sql

echo 'Copying database backup to offsite server ...'
scp ${BAK_DB}.tar.gz <location here>/backup/db/db-${BAK_DATETIME}.tar.gz

#ARCHIVING FILES / FOLDER
echo 'Archiving files and folders...'

FOLDERS=$(echo $BAK_SOURCES | tr "," "\n")
i=0
for F in $FOLDERS
do
  echo 'Archiving ' ${F} '...'
  i=`expr ${i} + 1`
  tar czPf ${BAK_FOLDER}/FILE_${i}_${BAK_DATETIME}.tar.gz ${F}
  scp ${BAK_FOLDER}/FILE_${i}_${BAK_DATETIME}.tar.gz <location here>/backup/files/FILE_${i}_${BAK_DATETIME}.tar.gz
done

#DELETE FILES OLDER THAN 7 days
echo 'Deleting backup older than '${KEEP_DAYS}' days'
find ${BAK_FOLDER} -type f -mtime +${KEEP_DAYS} -name '*.gz' -execdir rm -- {} \;
