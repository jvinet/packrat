#!/bin/bash

# Note: This module relies on the following external dependencies:
#   - s3curl.pl (packaged with packrat)
#   - cURL
#   - perl module: Digest::HMAC_SHA1

purge_s3() {
	verbose "[S3] cmd: s3curl.pl --id=$S3_ACCESS_KEY --key=$S3_SECRET_KEY --delete -- -s -S https://s3.amazonaws.com/$S3_BUCKET/$1"
	s3curl.pl --id=$S3_ACCESS_KEY --key=$S3_SECRET_KEY --delete -- -s -S https://s3.amazonaws.com/$S3_BUCKET/$1
}

mod_s3() {
	for f in $NEW_BACKUPS; do
		basef=`basename $f`
		verbose "[S3] Uploading $f to https://s3.amazonaws.com/${S3_BUCKET}/$basef"
		verbose "[S3] s3curl.pl --id=$S3_ACCESS_KEY --key=$S3_SECRET_KEY --put=$f -- -s -S https://s3.amazonaws.com/$S3_BUCKET/$basef"
		s3curl.pl --id=$S3_ACCESS_KEY --key=$S3_SECRET_KEY --put=$f -- -s -S https://s3.amazonaws.com/$S3_BUCKET/$basef
		[ $? -eq 0 ] || die "ERROR: command did not complete successfully"
	done
}
