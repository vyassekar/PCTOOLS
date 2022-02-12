#! /usr/bin/perl
#
use strict;

my %orig_string = ();
my %new_string = ();

if ($#ARGV < 1)
{
	die "usage: inputfile delimeter(,|;|TAB) fieldstoanonymze(commasep) outputfile\n";
}
my $inputfile = $ARGV[0];
my $delimeter = $ARGV[1];
my $fieldstoanon = $ARGV[2];
my @hashfields = split(',',$fieldstoanon);
my %mapping = ();
my $output = $ARGV[3];
open(f,"<$inputfile") or die "cant read inputfile\n";;
if ($delimeter eq "TAB")
{
	$delimeter = "\t";
}
open(out,">$output");
my $firstline = <f>;
chomp($firstline);
print out "$firstline\n";
my $data = "";
while ($data = <f>)
{
		chomp($data);
	my @fields = split($delimeter,$data);
	my $key = "";
	foreach $key  (@hashfields)
	{
		print "here $key $hashfields[$key] $fields[$key]\n";
		## use consistent hash map across multiple instances of the string
		if (not defined $mapping{$fields[$key]})
		{
			$mapping{$fields[$key]}  =  sprintf("%04X", rand(0xFFFF));
		}
		$fields[$key] = $mapping{$fields[$key]} ;
		print "after $key $hashfields[$key] $fields[$key]\n";
	}
	print out "$fields[0]";
	for (my $i =1; $i <= $#fields; $i++)
	{
		print out "$delimeter$fields[$i]";
	}
	print out "\n";
}
close(f);
close(out);


