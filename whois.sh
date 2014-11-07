#!/bin/sh
FILE=./ip_apnic
rm -f $FILE

cat /dev/null > UNICOM
cat /dev/null > TELECOM
cat /dev/null > CMCCNET
cat /dev/null > cn.net

wget http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest -O $FILE
grep 'apnic|CN|ipv4|' $FILE | cut -f 4,5 -d'|'|sed -e 's/|/ /g' | while read ip cnt
do
#echo $ip:$cnt
mask=$(cat << EOF | bc | tail -1
pow=32;
define log2(x) {
if (x<=1) return (pow);
  pow--;
  return(log2(x/2));
}
log2($cnt)
EOF)
echo $ip/$mask>> cn.net
#NETNAME=`whois $ip@whois.apnic.net | sed -e '/./{H;$!d;}' -e 'x;/netnum/!d' |grep ^netname | sed -e 's/.*:      \(.*\)/\1/g' | sed -e 's/-.*//g'`
NETNAME=`whois $ip@whois.apnic.net | awk '/^netname/ {print $2}' | sed -e 's/-.*//g'`
#NETNAME=`echo $NETNAME | sed -e 's/cJ/ /g' | awk -F' ' '{ printf $1; }'`
echo -e "$ip/$mask\t\t\t\t$NETNAME\t\t\t\t\c"
case $NETNAME in
UNICOM*)
  echo "echo $ip/$mask >> UNICOM"
  echo $ip/$mask >> UNICOM
;;
CHINANET*|CHINATELECOM*|BJTEL*)
  echo "echo $ip/$mask >> TELECOM"
  echo $ip/$mask >> TELECOM
;;
CMNET*)
  echo "echo $ip/$mask >> CMCCNET"
  echo $ip/$mask >> CMCCNET
;;
#CRTC|CRBjB|)
#  echo $ip/$mask >> CRTC
#;;
#TUNET|CERNET|CERBKB)
#  echo $ip/$mask >> CERNET
#;;
*)
  echo "echo $ip/$mask >> OTHER"
  echo $ip/$mask >> OTHER
;;
esac
#if [ -n "`whois $ip@whois.apnic.net | grep 'China Mobile'`" ]
#then
#echo $ip/$mask >> BMCCNET
#fi
done
