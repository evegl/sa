#!/usr/bin/perl
die "Usage: <data file> <siwtch-mac>\n"
#data file: nmap -sP -n x.x.x.x 
#switch-mac: show mac-address
unless @ARGV == 2;
my $ipfile=$ARGV[0];
my $macfile=$ARGV[1];
my %hash2;
open(FILE,"<$macfile") or die("can't open file:$!");
while (<FILE>) {
  chomp;
  $_=~s/(\w+)\.(\w+)\.(\w+)/$1:$2:$3/gi;
  $_=~/(\w+:\w+:\w+).*?((?:Fa|GigabitEthernet|Gi)\d\/\d(?:\/)?(?:.*)?)/;
  $mac2=uc($1);
  $hash2{($mac2)}=$2;
}
close(FILE);
open(FILE1,"<$ipfile") or die("can't open file:$!");
local $/;;
$array=<FILE1>;
close(FILE1);
$array=~s/[latency\)|up]\.\nMAC Address:/up.MAC Address:/sig;
my @array1=split/\n/,$array;
my %hash;
foreach(@array1) {
  chomp;
  $_=~/.*?\w+\s.*?(\d+\.\d+\.\d+\.\d+).*?(\w+):(\w+):(\w+):(\w+):(\w+):(\w+)/;
  $mac="$2$3:$4$5:$6$7";
  $hash{$mac}=$1;
}
foreach $macs(keys(%hash2)) {
  foreach (keys(%hash)) {
    if($macs eq $_) {
      print "MAC: $macs \tInterface: $hash2{$macs}\tHost: - Link_To_$hash{$_}\n";
    }
  }
}