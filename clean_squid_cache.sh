#!/bin/sh
squidcache_patch="/cache[1-6] /cache"
squidclient="/opt/squid/bin/squidclient"
grep -a -r $1 $squidcache_path | strings | awk "/^http:.*\.$1/ {print}" | while read url
do
$squidclient -m PURGE $url
done
[root@