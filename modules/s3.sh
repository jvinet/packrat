#!/bin/bash

# Note: This module relies on Tim Kay's aws utility, which is bundled
#       with Packrat. Make sure it's in the system path.

export EC2_ACCESS_KEY=$S3_ACCESS_KEY
export EC2_SECRET_KEY=$S3_SECRET_KEY

purge_s3() {
	verbose "[S3] aws rm $S3_BUCKET/$1"
	aws rm $S3_BUCKET/$1
}

list_s3() {
	aws --simple ls $S3_BUCKET | awk '{print $4}'
}

mod_s3() {
	for f in $NEW_BACKUPS; do
		basef=`basename $f`
		verbose "[S3] Uploading $f to ${S3_BUCKET}/$basef"
		full_cmd="aws put $S3_BUCKET/$basef $f"
		verbose "[S3] $full_cmd"
		$full_cmd
		# don't send sensitive data over email
		[ $? -eq 0 ] || diemail "ERROR: command did not complete successfully ($?)\n\nCommand: $full_cmd"
	done
}
