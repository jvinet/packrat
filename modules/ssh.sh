#!/bin/bash

purge_ssh() {
	verbose "[SSH] cmd: ssh -i ${SSH_KEY} ${SSH_USER}@${SSH_HOST} rm -f ${SSH_DIR}/${1}"
	ssh -i ${SSH_KEY} ${SSH_USER}@${SSH_HOST} rm -f ${SSH_DIR}/${1}
}

mod_ssh() {
	for f in $NEW_BACKUPS; do
		verbose "[SSH] cmd: scp -i ${SSH_KEY} $f ${SSH_USER}@${SSH_HOST}:${SSH_DIR}/${1}"
		[ "$SSH_BWLIMIT" ] && lim="-l $SSH_BWLIMIT"
		scp -i ${SSH_KEY} $lim $f ${SSH_USER}@${SSH_HOST}:${SSH_DIR}/${1}
		[ $? -eq 0 ] || die "ERROR: command did not complete successfully"
	done
}
