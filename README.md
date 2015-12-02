# drive2ftp
Cloning disk to ftp with splitting and checksumming

This simple script is intended to clone disk or partition to remote ftp. It can split data, compress it, calculate checksums and transfer compressed data and checksums to ftp server. 
After cloning is finished checksums can be re-calculated on ftp server usind md5sum, if you have ssh access to it.

This scrips uses mbuffer to speedup and checksumming, pigz to multithreaded compression and curl to handle ftp uploads

USAGE
./drive2ftp.sh /dev/sda 10240 ftp://user:password@my.ftp.server.com/sda.backup/
This will clone /dev/sda in 10GB chunks with compressing and checksumming. 

Restore script ftp2drive.sh added. There may be division problems in case of chunks not a multiple of 64k, so do not use such chunks during backup.
