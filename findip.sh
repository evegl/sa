#!/bin/sh
ip_prefix=$1
dev=$2
cat /dev/null > ip-$ip_prefix.txt
for ((i=2;i<=253;i++)) 
do 
        ip="${ip_prefix}.${i}"
        arping -c 1 -I ${dev} ${ip} 1>/dev/null  
        if [ $? -gt 0 ] 
        then 
                echo "$ip" >> ip-$ip_prefix.txt  
                echo "$ip"
        fi 
done