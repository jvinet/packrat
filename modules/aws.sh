#!/bin/bash

# This module requires Tim Kay's 'aws' perl script
# http://timkay.com/aws/
# follow the installation directions from the original site

# In addition, an ~/.awssecret file is required, as aws doesn't allow
# the keys to be specified on the command line - config settings are
# thus unused for these keys

purge_aws() {
	verbose "[AWS] s3rm $S3_BUCKET/$1"
	s3rm $S3_BUCKET/$1
}

mod_aws() {
	for f in $NEW_BACKUPS; do
		basef=`basename $f`
		verbose "[AWS] Uploading $f ${S3_BUCKET}/$basef"
		verbose "[AWS] aws put $S3_BUCKET/$basef $f"
		aws put $S3_BUCKET/$basef $f
		[ $? -eq 0 ] || die "ERROR: command did not complete successfully"
	done
}
