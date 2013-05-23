#!/usr/bin/perl -w

# This software code is made available "AS IS" without warranties of any
# kind.  You may copy, display, modify and redistribute the software
# code either by itself or as incorporated into your code; provided that
# you do not remove any proprietary notices.  Your use of this software
# code is at your own risk and you waive any claim against Amazon
# Digital Services, Inc. or its affiliates with respect to your use of
# this software code. (c) 2006 Amazon Digital Services, Inc. or its
# affiliates.

use strict;
use POSIX;

# you might need to use CPAN to get these modules.
# run perl -MCPAN -e "install <module>" to get them.

use Digest::HMAC_SHA1;
use MIME::Base64 qw(encode_base64);
use Getopt::Long qw(GetOptions);

# begin customizing here
my $CURL = "curl";

# stop customizing here

my $keyId;
my $secretKey;
my $contentType = "";
my $acl;
my $fileToPut;
my $doDelete;

GetOptions('id=s' => \$keyId, 'key=s' => \$secretKey, 'contentType=s' => \$contentType, 'acl=s' => \$acl, 'put=s' => \$fileToPut, 'delete' => \$doDelete);

die "Usage $0 --id AWSAccessKeyId --key SecretAccessKey --contentType text/plain --acl public-read --put index.html -- [curl-options]" 
  unless defined $keyId && defined $secretKey;

my $method = "";
if (defined $fileToPut) {
    $method = "PUT";
} elsif (defined $doDelete) {
    $method = "DELETE";
} else {
    $method = "GET";
}

my $contentMD5 = "";
my $resource;

# try to understand curl args
for my $arg (@ARGV) {
    # resource name
    if ($arg =~ /https?:\/\/([^\/]+)([^?]*)/) {
        if (length $2) {
            $resource = $2;
        } else {
            $resource = "/";
        }
        for my $attribute ("acl", "torrent", "logging") {
            if ($arg =~ /[?&]$attribute(=|&|$)/) {
                $resource = "$resource?$attribute";
                last;
            }
        }
    }
}

die "Couldn't find resource by digging through your curl command line args!"
    unless defined $resource;

my $httpDate = POSIX::strftime("%a, %d %b %Y %H:%M:%S +0000", gmtime);
my $aclHeaderToSign = defined $acl ? "x-amz-acl:$acl\n" : "";
my $stringToSign = "$method\n$contentMD5\n$contentType\n$httpDate\n$aclHeaderToSign$resource";
my $hmac = Digest::HMAC_SHA1->new($secretKey);
$hmac->add($stringToSign);
my $signature = encode_base64($hmac->digest, "");

my @args = ();
push @args, ("-H", "Date: $httpDate");
push @args, ("-H", "Authorization: AWS $keyId:$signature");
push @args, ("-H", "x-amz-acl: $acl") if (defined $acl);
push @args, ("-H", "content-type: $contentType") if (defined $contentType);
push @args, ("-T", $fileToPut) if (defined $fileToPut);
push @args, ("-X", "DELETE") if (defined $doDelete);
push @args, ("-k");

push @args, @ARGV;

system($CURL, @args) == 0 
  or die "Error running $CURL: $?";


