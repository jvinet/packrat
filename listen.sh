#!/bin/bash
#
# Run a push-style server for backup files.  The server
# receiving the backups runs this script, listening on a port.
# When the source server wants us to copy files, it sends us
# a small packet to our port and we initiate the scp.
#
# This is useful when you have strong firewall rules around
# your backup server and want to block all ingress traffic, even
# from your other servers.

docopy() {
	echo "Starting copy date=$1 host=$2"
	scp -i $HOME/.ssh/backup packrat@$2:/var/backup/*$1* /var/backup/
	echo "Copy finished"
}

while true; do
	echo "Listening..."
	nc -l -p 8451 | while read line; do
		d=`date +%Y%m%d`
		valid=`echo "$line" | grep -E "^\+PACKRAT [0-9]+ [A-Za-z0-9\.]+$"`
		if [ "$valid" = "" ]; then
			echo "Unrecognized command: $line"
			continue
		fi
		date=`echo $line | awk '{print $2}'`
		host=`echo $line | awk '{print $3}'`
		docopy $date $host &
	done
done
