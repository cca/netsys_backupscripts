#!/bin/bash
# Mark Y. Goh <mgoh@cca.edu>
# 2017-03-21
#
# postgresql backup script
# run as user postgres
# this is a daily cronjob
CWD=/backup

#set some variables for the log rotation
curDate=`date "+%Y-%m-%d"`
expDateFile=`date --date="last week" "+%Y-%m-%d"`
allDB=`/usr/bin/psql -U postgres -d postgres -q -t -c 'SELECT datname from pg_database' | grep -v 'template0' | grep -v 'template1'`

#create todays directory
if [ ! -d $CWD/daily/$HOST/$curDate ]; then
    mkdir $CWD/daily/$HOST/$curDate; 
fi

for i in $allDB; do
    /usr/bin/pg_dump -U postgres -Fp $i | gzip > $CWD/daily/$HOSTNAME/$curDate/$i.pg.gz 2>/tmp/err
    if [ "$?" -eq 0 ]; then
	logger "pgsql-backup-all.sh: $i backed up successfully"
    else
        /bin/cat /tmp/err | mail backupadmin@cca.edu -s "$HOSTNAME backup had an error"
	      logger "pgsql-backup-all.sh: $i back up FAILED"
  fi
done

#Delete file from a week ago
if [ -d $CWD/daily/$HOSTNAME/$expDateFile ]; then
	logger "pgsql-backup-all.sh: removing $CWD/daily/$HOSTNAME/$expDateFile"
        rm -rf $CWD/daily/$HOSTNAME/$expDateFile
fi

#cleanup err file
rm /tmp/err
