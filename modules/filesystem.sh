#!/bin/bash

find_master() {
	if [ "`uname`" = "Darwin" -o "`uname`" = "FreeBSD" ]; then
		m=`find $BACKUP_DIR -type f -name "${1}-*.master.1.dar" -print0 | xargs -0 stat -f "%B %N" | sort -k 1 -g | tail -n 1 | awk '{print $2}'`
	else
		m=`find $BACKUP_DIR -type f -name "${1}-*.master.1.dar" -printf "%A@ %f\n" | sort -k 1 -g | tail -n 1 | awk '{print $2}'`
	fi
	[ "$m" ] || return
	# shave off any possible extensions
	m="`echo $m | sed 's|.1.dar$||g' | sed 's|.tar.bz2||g'`"
	echo $m
}

mod_filesystem() {
	verbose "[FS] running..."
	unset opts
	if [ "$FS_METHOD" = "dar" ]; then
		method="dar"
		cmd="-c"
		opts="-n -y9 -D"
		fnprefix=
		cmdext=
		fileext=".dar"
		[ "$FS_SLICE_SIZE" ] && opts="$opts -s $FS_SLICE_SIZE"
		[ "$ENCRYPTION_KEY" ] && opts="$opts -K blowfish:$ENCRYPTION_KEY"
		incremental=0
		master=0
		if [ "$FS_INCREMENTAL" = "yes" ]; then
			incremental=1
			if [ "$FS_MASTER_FREQ" = "weekly" -a "$FS_MASTER_DAY" = "$DOW" ]; then
				master=1
			elif [ "$FS_MASTER_FREQ" = "monthly" -a "$FS_MASTER_DAY" = "$DOM" ]; then
				master=1
			fi
		fi
		for f in ${FS_EXCLUDE_FILES[@]}; do
			opts="$opts -X $f"
		done
		for f in ${FS_EXCLUDE_PATHS[@]}; do
			opts="$opts -P $f"
		done
	elif [ "$FS_METHOD" = "tar" ]; then
		# XXX: incomplete - do not use
		method="tar"
		cmd="-c"
		opts="-j"
		fnprefix="-f"
		cmdext=".tar.bz2"
		fileext=".tar.bz2"
	else
		die "Invalid FS_METHOD: $FS_METHOD"
	fi

	for targ in ${FS_TARGETS[@]}; do
		if [ ! -e "$targ" ]; then
			verbose "[FS] Target does not exist: $targ"
			continue
		fi
		finalopts="$opts -R $targ"
		noslash=`echo $targ | sed "s|/|-|g"`
		fnbase="${HOSTNAME}${noslash}-${TODAY}"
		if [ "$incremental" = "1" ]; then
			if [ "$master" = "0" ]; then
				m=`find_master "${HOSTNAME}${noslash}"`
				if [ "$m" ]; then
					finalopts="$finalopts -A ${BACKUP_DIR}/${m}${cmdext}"
					[ "$ENCRYPTION_KEY" ] && finalopts="$finalopts -J blowfish:$ENCRYPTION_KEY"
				else
					# missing the master, so we have to rebuild it
					verbose "[FS] Cannot find master archive, will build one"
					master=1
				fi
			fi
		fi
		if [ "$master" = "1" ]; then
			cmdfn="${fnbase}.master${cmdext}"
			realfn="${fnbase}.master${fileext}"
		else
			cmdfn="${fnbase}${cmdext}"
			realfn="${fnbase}${fileext}"
		fi
		verbose "[FS] backing up $targ to $realfn"
		full_cmd="$method $cmd ${BACKUP_DIR}/${cmdfn} $finalopts"
		verbose "[FS] cmd: $full_cmd"
		$full_cmd
		ret=$?
		if [ $ret -ne 0 ]; then
			# retcode 11 is allowed: Dar uses it if a file changed while being read.
			[ $ret -eq 11 ] || diemail "ERROR: command did not complete successfully ($ret)\n\nCommand: $full_cmd"
		fi
		for f in ${BACKUP_DIR}/${cmdfn}.*; do
			NEW_BACKUPS="$NEW_BACKUPS $f"
		done
	done
}
