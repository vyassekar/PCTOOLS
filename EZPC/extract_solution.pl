#! /usr/bin/perl 

use strict;

if ($#ARGV < 0)
{
	die "usage: solutionfile outputfile_picked outputfile_dropped\n";
}

open(f,"<$ARGV[0]") or die "Cant open the file $ARGV[0]\n";
open(out1,">$ARGV[1]");
open(out2,">$ARGV[2]");
my $data = "";
my $currentcandidate = "";
while ($data = <f>)
{
	chomp($data);
	if ($data =~ /d_(\w+)/)
	{
		$currentcandidate = $1;
	}
	if ($data =~  /\*\s+1\s+0\s+1/)
	{
		#print "Selected $currentcandidate\n";
		print out1 "$currentcandidate,1\n"
	} 
	if ($data =~  /\*\s+0\s+0\s+1/)
	{
		#print "Dropped $currentcandidate\n";
		print out2 "$currentcandidate,0\n"
	}
}

close(out1);
close(out2);
