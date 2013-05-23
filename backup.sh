#!/bin/bash
#
# The counterpart to listen.sh, this script is run on the source
# server. It then pings the storage server so it can pick up the
# files.

/usr/bin/packrat.sh -v
[ $? -eq 0 ] || exit 1

# ping the backup server so it knows the archive is ready for copy
d=`date +%Y%m%d`
echo "+PACKRAT $d `hostname -s`" | nc -w 1 backup 8451
