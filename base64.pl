#!/usr/bin/perl -w
use Getopt::Long;
use MIME::Base64;
use strict;
sub usage ();
sub print_help ();
sub process_arguments ();
sub usage()
{
  print STDERR << "EOF";
Missing arguments!
Usage:base64 [OPTION] [STRINGS]
-e, --encode          Encode data.
-d, --decode          Decode data.
-h, --help            Display this help and exit.
EOF
   exit 1;
}
sub print_help()
{
  print STDOUT << "EOF";
Usage:base64 [OPTION] [STRINGS]
-e, --encode          Encode data.
-d, --decode          Decode data.
-h, --help            Display this help and exit.
EOF
   exit 0;
}
my ($status,$encode,$decode,$help);
sub process_arguments() {
   GetOptions(
        "e=s" => \$encode,"encode" => \$encode,
        "d=s" => \$decode,"decode" => \$decode,
        "h"   => \$help,"help" => \$help
   );
   print_help() if $help;
   
}
if (@ARGV == 0) {
   usage();
}
process_arguments();
print encode_base64("$encode") if $encode;
print decode_base64("$decode") if $decode;
print "\n";
exit 0;