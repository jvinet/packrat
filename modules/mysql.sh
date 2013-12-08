#!/bin/bash

mod_mysql() {
	verbose "[MYSQL] running..."
	for db in "${MYSQL_TARGETS[@]}"; do
		opts="--opt"
		[ "$MYSQL_PASS" != "" ] && opts="$opts -p${MYSQL_PASS}"
		[ "$MYSQL_HOST" != "" ] && opts="$opts -h ${MYSQL_HOST}"
		[ "$MYSQL_PORT" != "" ] && opts="$opts -P ${MYSQL_PORT}"
		if [ "$db" = "__ALL__" ]; then
			opts="$opts -A"
			dbname="all"
		else
			opts="$opts $db"
			dbname=$db
		fi
		fn="${BACKUP_DIR}/$HOSTNAME-mysql-${dbname}-$TODAY.sql.bz2"
		verbose "[MYSQL] backup up database: $db"
		if [ "$ENCRYPTION_KEY" ]; then
			# decrypt with 'openssl enc -d -bf -pass pass:<password> -in infile -out outfile'
			verbose "[MYSQL] cmd: mysqldump -u $MYSQL_USER $opts | bzip2 | openssl enc -e -salt -bf -pass pass:$ENCRYPTION_KEY >$fn"
			mysqldump -u $MYSQL_USER $opts | bzip2 | openssl enc -e -salt -bf -pass pass:$ENCRYPTION_KEY >$fn
		else
			verbose "[MYSQL] cmd: mysqldump -u $MYSQL_USER $opts | bzip2 >$fn"
			mysqldump -u $MYSQL_USER $opts | bzip2 >$fn
		fi
		# don't send sensitive data over email
		[ $? -eq 0 ] || diemail "ERROR: command did not complete successfully ($?)\n\nCommand: mysqldump <xxx"
		NEW_BACKUPS="$NEW_BACKUPS $fn"
	done
}
