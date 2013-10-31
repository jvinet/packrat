#!/bin/bash

mod_postgresql() {
	verbose "[POSTGRESQL] running..."
	for db in "${POSTGRESQL_TARGETS[@]}"; do
		cmd="pg_dump"
		opts=""
		[ "$POSTGRESQL_USER" != "" ] && opts="$opts -U ${POSTGRESQL_USER}"
		[ "$POSTGRESQL_HOST" != "" ] && opts="$opts -h ${POSTGRESQL_HOST}"
		[ "$POSTGRESQL_PORT" != "" ] && opts="$opts -p ${POSTGRESQL_PORT}"
		if [ "$db" = "__ALL__" ]; then
			cmd="pg_dumpall"
			dbname="all"
		else
			opts="$opts $db"
			dbname=$db
		fi
		fn="${BACKUP_DIR}/$HOSTNAME-postgresql-${dbname}-$TODAY.sql.bz2"
		verbose "[POSTGRESQL] backup up database: $db"
		if [ "$POSTGRESQL_ENCRYPTION_KEY" ]; then
			# decrypt with 'openssl enc -d -bf -pass pass:<password> -in infile -out outfile'
			verbose "[POSTGRESQL] cmd: $cmd $opts | bzip2 | openssl enc -e -salt -bf -pass pass:$POSTGRESQL_ENCRYPTION_KEY >$fn"
			$cmd $opts | bzip2 | openssl enc -e -salt -bf -pass pass:$POSTGRESQL_ENCRYPTION_KEY >$fn
		else
			verbose "[POSTGRESQL] cmd: $cmd $opts | bzip2 >$fn"
			$cmd $opts | bzip2 >$fn
		fi
		[ $? -eq 0 ] || die "ERROR: command did not complete successfully"
		NEW_BACKUPS="$NEW_BACKUPS $fn"
	done
}
