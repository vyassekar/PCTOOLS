#! /usr/bin/perl 

use strict;

if ($#ARGV < 0)
{
	die "usage: solutionfile slotsfile outputfile\n";
}

my $allslotsfile = $ARGV[1];

## read slots file 

open(f,"<$allslotsfile") or die "Cant open slots file\n";
my %slotindex = ();
my %rev_slotindex = ();
my $data= "";
while ($data = <f>)
{
	chomp($data);
	my @fields = split(/\s+/,$data);
	my $slotid = $fields[0];
	$slotindex{$slotid} = $fields[1];
	$rev_slotindex{$fields[1]} = $slotid;
}
close(f);



open(f,"<$ARGV[0]") or die "Cant open the file $ARGV[0]\n";
open(out1,">$ARGV[2]");
my $data = "";
my $currentcandidate = "";
my %assigned = ();

my ($paperid,$currentday,$starthr,$startmin,$endhr,$endmins);
while ($data = <f>)
{
	chomp($data);
	if ($data =~ /d\_(\d+)\_(\d+)\_(\d+)\_(\d+)\_(\d+)\_(\d+)/)
	{
		$paperid =$1;
		$currentday =$2;
		$starthr = $3;
		$startmin= $4;
		$endhr = $5;
		$endmins = $6;
	}
	if ($data =~  /\*\s+1\s+0\s+1/)
	{
		my $slotid = $currentday."_".$starthr."_".$startmin."_".$endhr."_".$endmins;;
		my $index = $slotindex{$slotid};
		$assigned{$paperid} = $index;
	} 
}
close(out1);
my $paper = "";
foreach $paper (sort {$assigned{$a} <=> $assigned{$b}} keys %assigned)
{
	print "$assigned{$paper} $paper $rev_slotindex{$assigned{$paper}}\n";
}
