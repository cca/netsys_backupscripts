#!/bin/bash
# Mark Y. Goh <mgoh@cca.edu>
# 2017-03-21
# mysql backup script
# this is a daily cronjob

CWD=/backup
source /root/.secret.conf #DB_PASS DB_USER defined in this file
curDate=`date "+%Y-%m-%d"`
expDateFile=`date --date="5 days ago" "+%Y-%m-%d"`

# Get the database list, exclude information_schema
for db in $(mysql -B -s -u $DB_USER --password=$DB_PASS -e 'show databases' | grep -v information_schema| grep -v performance_schema); do
  if [ ! -d $CWD/daily/$HOSTNAME/$curDate ]; then
	    mkdir $CWD/daily/$HOSTNAME/$curDate
  fi
	# Dump each database in a separate file
	mysqldump -u $DB_USER --password=$DB_PASS $db | gzip > $CWD/daily/$HOSTNAME/$curDate/$curDate-$db.sql.gz 2>$CWD/err
	if [ "$?" -eq 0 ]
    then
        logger "mysql-backup2.sh: $db on $HOSTNAME backed up successfully"
    else
        logger "mysql-backup2.sh: $db back up for $HOSTNAME FAILED"
        /bin/cat /tmp/err | mail backupadmin@cca.edu -s "$HOSTNAME backup report errors"
	fi
done

# Cleanup files
if [ -a /tmp/err ]
  then
    rm /tmp/err
fi

# Delete file from a week ago
rm -rf $CWD/daily/$HOSTNAME/$expDateFile
