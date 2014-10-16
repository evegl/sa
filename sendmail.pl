#!/usr/bin/perl
use strict;
use Net::SMTP;
use File::Basename;
@ARGV == 2 || die "Syntax: ",basename($0)," <Subject> <Email>\n";
$|=1;
open(INFO,"|cat") or die;
my $smtp;
my $smtp_server = 'yoursmtpserver';
my $from_mail = 'admin@yourdomain.com';
my $to_mail = $ARGV[1];
my $subject = $ARGV[0];
chomp(my @info = <STDIN>);
# Used Net::SMTP modules
$smtp = Net::SMTP->new(${smtp_server}, Timeout => 60);
$smtp->mail(${from_mail});
$smtp->to(${to_mail});
$smtp->data();
$smtp->datasend("To:${to_mail}\n");
$smtp->datasend("From:${from_mail}\n");
$smtp->datasend("Subject: ${subject}\n");
$smtp->datasend("\n");
foreach (@info) {
   $smtp->datasend("$_\n");
}
$smtp->datasend();
$smtp->quit;
close(INFO);