use POSIX;
use strict;
use lib "/usr/local/nagios/libexec"  ;
use utils qw($TIMEOUT %ERRORS &print_revision &support);
use Net::SNMP;
use Getopt::Long;
&Getopt::Long::config('bundling');
my $PROGNAME = "check_f5PoolStatus";
sub print_help ();
sub usage ();
sub process_arguments ();
my $timeout;
my $status;
my $state = "UNKNOWN";
my $answer = "";
my $snmpkey;
my $community = "public";
my $maxmsgsize = 1472 ; # Net::SNMP default is 1472
my ($seclevel, $authproto, $secname, $authpass, $privpass, $auth, $priv, $context);
my $port = 161;
my @snmpoids;
my $snmpBase = '.1.3.6.1.4.1.3375.2.2.10.1.2.1.22';
my $snmpDescription = '.1.3.6.1.4.1.3375.2.2.10.1.2.1.19';
my $snmpVsState = '.1.3.6.1.4.1.3375.2.2.10.1.2.1.25';
my $hostname;
my $free_percent;
my $session;
my $error;
my $response;
my $snmp_version = 2 ;
my $ifXTable;
my $opt_h ;
my $opt_V ;
my $val_h = "1";
my $val_l;
my $key;
my $lastc;
my $PoolDescr;
my $dormantWarn;
my $adminWarn;
my $name;
my $PoolState;
$status = process_arguments();
$SIG{'ALRM'} = sub {
     print ("ERROR: No snmp response from $hostname (alarm)\n");
     exit $ERRORS{"UNKNOWN"};
};
alarm($timeout);
if (defined $PoolDescr) {
        # escape "/" in PoolDescr
        $PoolDescr =~ s/\//\\\//g;
        $status=fetch_PoolDescr();  # if using on device with large number of interfaces
                                                          # recommend use of SNMP v2 (get-bulk)
        if (not defined $status) {
                $state = "UNKNOWN";
                printf "$state: could not retrive PoolDescr snmpkey - $status-$snmpkey\n";
                $session->close;
                exit $ERRORS{$state};
        }
}
$snmpBase = $snmpBase . "." . $snmpkey;
$snmpDescription = $snmpDescription . "." . $snmpkey;
$snmpVsState = $snmpVsState . "." . $snmpkey;
push(@snmpoids,$snmpBase);
push(@snmpoids,$snmpDescription);
push(@snmpoids,$snmpVsState);
   if (!defined($response = $session->get_request(@snmpoids))) {
      $answer=$session->error;
      $session->close;
      $state = 'WARNING';
      print ("$state: SNMP error: $answer\n");
      exit $ERRORS{$state};
   }
   $PoolState = $response->{$snmpBase}; 
   if (not $PoolState =~ /\d/ ){
        $state = 'WARNING';
   }elsif ( $PoolState > $val_h ){
        $state = 'CRITICAL'; 
   }else{
        $state = 'OK';
   }
   $answer = sprintf("host '%s', %s that VS is %s\n",
   $hostname,
   $response->{$snmpVsState},
   $response->{$snmpDescription},
   );
print ("$state: $answer");
exit $ERRORS{$state};
sub fetch_PoolDescr {
        if (!defined ($response = $session->get_table($snmpDescription))) {
                $answer=$session->error;
                $session->close;
                $state = 'CRITICAL';
                printf ("$state: SNMP error with snmp version $snmp_version ($answer)\n");
                $session->close;
                exit $ERRORS{$state};
        }
        foreach $key ( keys %{$response}) {
                if ($response->{$key} =~ /^$PoolDescr$/) {
                        $key =~ /^.*\.3375\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.(.*)$/;
                        $snmpkey = $1;
                        #print "$PoolDescr = $key / $snmpkey \n";  #debug
                }
        }
        unless (defined $snmpkey) {
                $session->close;
                $state = 'CRITICAL';
                printf "$state: Could not match $PoolDescr on $hostname\n";
                exit $ERRORS{$state};
        }
        return $snmpkey;
}
sub usage() {
  printf "\nMissing arguments!\n";
  printf "\n";
  printf "usage: \n";
  printf "check_f5PoolStatus -k <Pool_Index>|-P <Pool_Name> -H <HOSTNAME> [-C <community>]\n";
  printf "Copyright (C) 2007 Jimi^H.\n";
  printf "check_f5PoolStatus comes with ABSOLUTELY NO WARRANTY\n";
  printf "This programm is licensed under the terms of the ";
  printf "GNU General Public License\n(check source code for details)\n";
  printf "\n\n";
  exit $ERRORS{"UNKNOWN"};
}
sub print_help() {
        printf "check_f5PoolStatus plugin for Nagios monitors operational \n";
        printf "status of a particular network interface on the target host\n";
        printf "\nUsage:\n";
        printf "   -H (--hostname)   Hostname to query - (required)\n";
        printf "   -C (--community)  SNMP read community (defaults to public,\n";
        printf "                     used with SNMP v1 and v2c\n";
        printf "   -v (--snmp_version)  1 for SNMP v1 (default)\n";
        printf "                        2 for SNMP v2c\n";
        printf "                        SNMP v2c will use get_bulk for less overhead\n";
        printf "                        if monitoring with -d\n";
        printf "   -L (--seclevel)   choice of \"noAuthNoPriv\", \"authNoPriv\", or     \"authPriv\"\n";
        printf "   -U (--secname)    username for SNMPv3 context\n";
        printf "   -c (--context)    SNMPv3 context name (default is empty      string)\n";
        printf "   -A (--authpass)   authentication password (cleartext ascii or localized key\n";
        printf "                     in hex with 0x prefix generated by using   \"snmpkey\" utility\n"; 
        printf "                     auth password and authEngineID\n";
        printf "   -a (--authproto)  Authentication protocol ( MD5 or SHA1)\n";
        printf "   -X (--privpass)   privacy password (cleartext ascii or localized key\n";
        printf "                     in hex with 0x prefix generated by using   \"snmpkey\" utility\n"; 
        printf "                     privacy password and authEngineID\n";
        printf "   -k (--key)        SNMP f5PoolIndex value\n";
        printf "   -P (--pool)       SNMP Pool Name Descr\n";
        printf "   -p (--port)       SNMP port (default 161)\n";
        printf "   -M (--maxmsgsize) Max message size - usefull only for v1 or v2c\n";
        printf "   -t (--timeout)    seconds before the plugin times out (default=$TIMEOUT)\n";
        printf "   -V (--version)    Plugin version\n";
        printf "   -h (--help)       usage help \n\n";
        printf " -k must be specified\n\n";
        printf "Note: either -k must be specified\n";
        printf "intensive.  Use it sparingly or not at all.  -n is used to match against\n";
        printf "a much more descriptive ifName value in the IfXTable to verify that the\n";
        printf "snmpkey has not changed to some other network interface after a reboot.\n\n";
        print_revision($PROGNAME, '$Revision: 1.7 $');
}
sub process_arguments() {
        $status = GetOptions(
                        "V"   => \$opt_V, "version"    => \$opt_V,
                        "h"   => \$opt_h, "help"       => \$opt_h,
                        "v=i" => \$snmp_version, "snmp_version=i"  => \$snmp_version,
                        "C=s" => \$community, "community=s" => \$community,
                        "L=s" => \$seclevel, "seclevel=s" => \$seclevel,
                        "a=s" => \$authproto, "authproto=s" => \$authproto,
                        "U=s" => \$secname,   "secname=s"   => \$secname,
                        "A=s" => \$authpass,  "authpass=s"  => \$authpass,
                        "X=s" => \$privpass,  "privpass=s"  => \$privpass,
                        "c=s" => \$context,   "context=s"   => \$context,
                        "k=s" => \$snmpkey, "key=s",\$snmpkey,
                        "P=s" => \$PoolDescr, "pool=s" => \$PoolDescr,
                        "p=i" => \$port,  "port=i" =>\$port,
                        "H=s" => \$hostname, "hostname=s" => \$hostname,
                        "w=s" => \$dormantWarn, "warn=s" => \$dormantWarn,
                        "D=s" => \$adminWarn, "admin-down=s" => \$adminWarn,
                        "M=i" => \$maxmsgsize, "maxmsgsize=i" => \$maxmsgsize,
                        "t=i" => \$timeout,    "timeout=i" => \$timeout,
                        );
        if ($status == 0){
                print_help();
                exit $ERRORS{'OK'};
        }
  
        if ($opt_V) {
                print_revision($PROGNAME,'$Revision: 1.7 $ ');
                exit $ERRORS{'OK'};
        }
        if ($opt_h) {
                print_help();
                exit $ERRORS{'OK'};
        }
        if (! utils::is_hostname($hostname)){
                usage();
                exit $ERRORS{"UNKNOWN"};
        }
        unless (defined $snmpkey || defined $PoolDescr){
                printf "Either a valid snmpkey key (-k) or a pool (-P) must be provided)\n";
                usage();
                exit $ERRORS{"UNKNOWN"};
        }
        unless (defined $timeout) {
                $timeout = $TIMEOUT;
        }
        if ($snmp_version =~ /3/ ) {
                # Must define a security level even though default is noAuthNoPriv
                # v3 requires a security username
                if (defined $seclevel  && defined $secname) {
                        # Must define a security level even though defualt is noAuthNoPriv
                        unless ( grep /^$seclevel$/, qw(noAuthNoPriv authNoPriv authPriv) ) {
                                usage();
                                exit $ERRORS{"UNKNOWN"};
                        }
                        # Authentication wanted
                        if ( $seclevel eq 'authNoPriv' || $seclevel eq 'authPriv' ) {
                                unless ( $authproto eq 'MD5' || $authproto eq 'SHA1' ) {
                                        usage();
                                        exit $ERRORS{"UNKNOWN"};
                                }
                                if ( !defined $authpass) {
                                        usage();
                                        exit $ERRORS{"UNKNOWN"};
                                }else{
                                        if ($authpass =~ /^0x/ ) {
                                                $auth = "-authkey => $authpass" ;
                                        }else{
                                                $auth = "-authpassword => $authpass";
                                        }
                                }
                        }
                        # Privacy (DES encryption) wanted
                        if ($seclevel eq  'authPriv' ) {
                                if (! defined $privpass) {
                                        usage();
                                        exit $ERRORS{"UNKNOWN"};
                                }else{
                                        if ($privpass =~ /^0x/){
                                                $priv = "-privkey => $privpass";
                                        }else{
                                                $priv = "-privpassword => $privpass";
                                        }
                                }
                        }
                        # Context name defined or default
                        unless ( defined $context) {
                                $context = "";
                        }
 
                }else {
                                        usage();
                                        exit $ERRORS{'UNKNOWN'}; ;
                }
        } # end snmpv3
        if ( $snmp_version =~ /[12]/ ) {
        ($session, $error) = Net::SNMP->session(
                        -hostname  => $hostname,
                        -community => $community,
                        -port      => $port,
                        -version        => $snmp_version,
                        -maxmsgsize => $maxmsgsize
                );
                if (!defined($session)) {
                        $state='UNKNOWN';
                        $answer=$error;
                        print ("$state: $answer");
                        exit $ERRORS{$state};
                }
        }elsif ( $snmp_version =~ /3/ ) {
                if ($seclevel eq 'noAuthNoPriv') {
                        ($session, $error) = Net::SNMP->session(
                                -hostname  => $hostname,
                                -port      => $port,
                                -version  => $snmp_version,
                                -username => $secname,
                        );
                }elsif ( $seclevel eq 'authNoPriv' ) {
                        ($session, $error) = Net::SNMP->session(
                                -hostname  => $hostname,
                                -port      => $port,
                                -version  => $snmp_version,
                                -username => $secname,
                                $auth,
                                -authprotocol => $authproto,
                        );
                }elsif ($seclevel eq 'authPriv' ) {
                        ($session, $error) = Net::SNMP->session(
                                -hostname  => $hostname,
                                -port      => $port,
                                -version  => $snmp_version,
                                -username => $secname,
                                $auth,
                                -authprotocol => $authproto,
                                $priv
                        );
                }

                if (!defined($session)) {
                                        $state='UNKNOWN';
                                        $answer=$error;
                                        print ("$state: $answer");
                                        exit $ERRORS{$state};
                }
        }else{
                $state='UNKNOWN';
                print ("$state: No support for SNMP v$snmp_version yet\n");
                exit $ERRORS{$state};
        }
}