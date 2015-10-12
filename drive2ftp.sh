#!/bin/bash

# REQUIREMENTS:
# dd, blockdev, mbuffer, curl, pigz; md5sum on ftp server to check sums
#USAGE: drive2ftp.sh /dev/sda 10 ftp://user:pass@server/dir/

#apt-get install mbuffer curl pigz

DD=dd
DD_OPTS="status=none"
MBUFFER=mbuffer

CURL=curl
GZIP=pigz
BLOCKDEV=blockdev

DRIVE=$1
SPLIT=$2
URI=$3
DRIVE_NICK=$(basename $DRIVE)

#Some tunnable vars
DRIVE_BUF=100M #drive buffer, post-dd, pre-gzip

GZIP_BUF=20M #gzip buffer, post-gzip, pre-curl
DD_BS=$[64*1024] #dd block size 

#empty to skip uncompressed checksum calculation
#SRC_MD5="--md5"
SRC_MD5=""

# 1 compression minimal, 140% CPU on 100MB/sec
GZIP_OPTS="-1 -c -n"
# 4 compression minimal to compress zeroes, 240% CPU on 100MB/sec
#GZIP_OPTS="-4 -c -n"

TMPDIR=/tmp
MYPID=$$
DB_LOG=$TMPDIR/db.$MYPID.log
GB_LOG=$TMPDIR/gb.$MYPID.log
HASHLIST_RAW=$DRIVE_NICK-$MYPID-md5sum-raw.txt
HASHLIST=$DRIVE_NICK-$MYPID-md5sum.txt

DRIVE_SZ=$($BLOCKDEV --getsize64 $DRIVE)
SZ_DIGITS=$(echo -n $DRIVE_SZ|wc -c)

let SPLIT_SZ=SPLIT*1024*1024/DD_BS*DD_BS #SPLIT_SZ is now dividable to DD_BS
for ((i=0;i<$DRIVE_SZ;i+=$SPLIT_SZ));do 
    echo $i
    let SKIPB=i/DD_BS
    let COUNTB=SPLIT_SZ/DD_BS
    # Generating filename
    let FN_START=SKIPB*DD_BS
    let FN_END=(SKIPB+COUNTB)*DD_BS
    if [ $FN_END -gt $DRIVE_SZ ];then
	let FN_END=DRIVE_SZ
    fi
    let FN_END=FN_END-1
    FN="$DRIVE_NICK-$MYPID-$(printf %0${SZ_DIGITS}u $FN_START)-$(printf %0${SZ_DIGITS}u $FN_END)"

    $DD if=$DRIVE bs=$DD_BS skip=$SKIPB count=$COUNTB $DD_OPTS|$MBUFFER $SRC_MD5 -q -m $DRIVE_BUF -l $DB_LOG|$GZIP $GZIP_OPTS|$MBUFFER --md5 -q -m $GZIP_BUF -l $GB_LOG |$CURL -T - "$URI/$FN.gz"

    DRIVE_HASH=$(awk '/MD5 hash/ {print $3}' $DB_LOG)
    GZIP_HASH=$(awk '/MD5 hash/ {print $3}' $GB_LOG)

    echo "$DRIVE_HASH $FN" >> $TMPDIR/$HASHLIST_RAW
    echo "$GZIP_HASH $FN.gz" >> $TMPDIR/$HASHLIST
    #put checksums every time to keep them actual on ftp
    $CURL -s -T $TMPDIR/$HASHLIST_RAW "$URI/$HASHLIST_RAW"
    $CURL -s -T $TMPDIR/$HASHLIST "$URI/$HASHLIST"

done
rm -f $DB_LOG $GB_LOG

