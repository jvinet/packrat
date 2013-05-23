#!/bin/bash

VERSION="0.3.2"
OPT_VERBOSE=0
OPT_CONFIG="/etc/packrat.conf"
OPT_MODPATH="/usr/share/packrat/modules"
OPT_PURGE=0

TODAY=`date +%Y%m%d`
DOW=`date +%a`
DOM=`date +%d`
NEW_BACKUPS=

usage() {
	echo "packrat version $VERSION"
	echo "Copyright (C) 2007, Judd Vinet <jvinet@zeroflux.org>"
	echo 
	echo "Usage: packrat [options]"
	echo 
	echo "Options:"
	echo "  -c <file>    Path to config file"
	echo "  -h           This help message"
	echo "  -v           Verbose output"
	echo "  -P           Purge old archives and exit"
	echo "  -p <days>    Override PURGE_ARCHIVES in config file"
	echo "  -m <methods> Override BACKUP_METHODS in config file (comma-separated)"
	echo "  -u <methods> Override UPLOAD_METHODS in config file (comma-separated)"
	echo "  -U <date>    Perform upload stage only (date format: YYYYMMDD)"
	echo
}
die() {
	echo "$*" >&2
	exit 1
}
verbose() {
	[ "$OPT_VERBOSE" = "1" ] && echo $*
}
run_module() {
	mod_$1
}
module_purge() {
	purge_$1 $2
}

#
# Parse commandline options
#
while getopts "Phvc:p:m:u:U:-" opt; do
	case $opt in
		P) OPT_PURGE=1 ;;
		c) OPT_CONFIG=$OPTARG ;;
		v) OPT_VERBOSE=1 ;;
		p) OPT_PURGE_ARCHIVES=$OPTARG ;;
		m) OPT_BACKUP_METHODS=$OPTARG ;;
		u) OPT_UPLOAD_METHODS=$OPTARG ;;
		U) OPT_UPLOAD_DATE=$OPTARG ;;
		h) usage; exit 0; ;;
		*) usage; exit 1; ;;
	esac
done

#
# Read config file
#
[ -r $OPT_CONFIG ] || die "Cannot read config file: $OPT_CONFIG"
source $OPT_CONFIG

#
# Handle overrides
#
[ "$OPT_PURGE_ARCHIVES" ] && PURGE_ARCHIVES=$OPT_PURGE_ARCHIVES
if [ "$OPT_BACKUP_METHODS" ]; then
	BACKUP_METHODS=()
	for m in `echo $OPT_BACKUP_METHODS | sed 's|,| |g'`; do
		BACKUP_METHODS=(${BACKUP_METHODS[*]} $m)
	done
fi
if [ "$OPT_UPLOAD_METHODS" ]; then
	UPLOAD_METHODS=()
	for m in `echo $OPT_UPLOAD_METHODS | sed 's|,| |g'`; do
		UPLOAD_METHODS=(${UPLOAD_METHODS[*]} $m)
	done
fi

#
# Load modules
#
for f in $OPT_MODPATH/*.sh; do
	source $f
done

#
# Purge old archives
#
for f in `find $BACKUP_DIR -type f -mtime +$PURGE_ARCHIVES`; do
	verbose "Removing old archive: $f"
	rm -f $f
	for m in "${UPLOAD_METHODS[@]}"; do
		module_purge $m `basename $f`
	done
done
[ "$OPT_PURGE" = "1" ] && exit 0

if [ "$OPT_UPLOAD_DATE" ]; then
	NEW_BACKUPS=`/bin/ls $BACKUP_DIR/*$OPT_UPLOAD_DATE*`
else
	#
	# Pass control to each backup module
	# 
	for m in ${BACKUP_METHODS[@]}; do
		run_module $m
	done
fi

#
# Pass control to each file-upload module
#
for m in ${UPLOAD_METHODS[@]}; do
	run_module $m
done

exit 0
