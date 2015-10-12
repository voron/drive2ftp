# drive2ftp
Cloning disk to ftp with splitting and checksumming

This simple script is intended to clone disk or partition to remote ftp. It can split data, compress it, calculate checksums and transfer compressed data and checksums to ftp server. 
After cloning is finished checksums can be re-calculated on ftp server usind md5sum, if you have ssh access to it.

This scrips uses mbuffer to speedup and checksumming, pigz to multithreaded compression and curl to handle ftp uploads

TODO: restore script :)