#!/bin/bash

purge_ssh() {
	verbose "[SSH] cmd: ssh -i ${SSH_KEY} ${SSH_USER}@${SSH_HOST} rm -f ${SSH_DIR}/${1}"
	ssh -i ${SSH_KEY} ${SSH_USER}@${SSH_HOST} rm -f ${SSH_DIR}/${1}
}

list_ssh() {
	ssh -i ${SSH_KEY} ${SSH_USER}@${SSH_HOST} /bin/ls -1 ${SSH_DIR}
}

mod_ssh() {
	for f in $NEW_BACKUPS; do
		verbose "[SSH] cmd: scp -i ${SSH_KEY} $f ${SSH_USER}@${SSH_HOST}:${SSH_DIR}/${1}"
		[ "$SSH_BWLIMIT" ] && lim="-l $SSH_BWLIMIT"
		full_cmd="scp -i ${SSH_KEY} $lim $f ${SSH_USER}@${SSH_HOST}:${SSH_DIR}/${1}"
		$full_cmd
		[ $? -eq 0 ] || diemail "ERROR: command did not complete successfully ($?)\n\nCommand: $full_cmd"
	done
}
