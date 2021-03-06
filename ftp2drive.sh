#!/bin/bash

# REQUIREMENTS:
# dd, blockdev, mbuffer, curl, pigz; md5sum on f[35;71;24Mtp server to check sums
#USAGE: sh ftp2drive.sh /dev/sda sda-PID-md5sum.txt ftp://user:pass@server/dir/

#apt-get install mbuffer curl pigz
#yum  -y install mbuffer curl pigz util-linux coreutils

DD=dd
DD_OPTS="status=noxfer"
MBUFFER=mbuffer

CURL=curl
GZIP=pigz
BLOCKDEV=blockdev

DRIVE=$1
HASHLIST=$2
URI=$3


#Some tunnable vars
DRIVE_BUF=100M #drive buffer, post-gzip, pre-dd

GZIP_BUF=20M #gzip buffer, post-curl, pre-gzip
DD_BS=$[64*1024] #dd block size 

#empty to skip uncompressed checksum calculation
#SRC_MD5="--md5"
SRC_MD5=""

# d decompress the compressed input
GZIP_OPTS="-d -c -n"



TMPDIR=/tmp
MYPID=$$
DB_LOG=$TMPDIR/db.$MYPID.log
GB_LOG=$TMPDIR/gb.$MYPID.log

$CURL -s -o $TMPDIR/$HASHLIST "$URI/$HASHLIST"

for FN in `cat $TMPDIR/$HASHLIST| awk '{print $2}'` ; do
    FN_START=$(echo -n $FN|egrep  -o "[0-9]{10,}" | head -1|sed 's/^0*//')
    let SEEK=FN_START/DD_BS
    if [ "$SEEK" != 0 ]; then 
        SEEK_STR="seek=$SEEK"
    else
        SEEK_STR=""
    fi
    echo -n "$FN "
    $CURL -s "$URI/$FN" | $MBUFFER --md5 -q -m $GZIP_BUF -l $GB_LOG |$GZIP $GZIP_OPTS|$MBUFFER $SRC_MD5 -q -m $DRIVE_BUF -l $DB_LOG|$DD of=$DRIVE bs=$DD_BS $SEEK_STR $DD_OPTS
done


