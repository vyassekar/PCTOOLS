#! /usr/bin/perl
use strict;
#

sub  change_to_alphanumeric_lowercase
{
	my $input = shift;
	my $word = $input;
	$word =~ s/[^a-zA-Z0-9]+//g;
	$word = lc $word;
	return $word;
}

use strict;
open(schemafile,"<schema.txt");


my @sheet_features=();
my %inverse_features = ();
my @postprocess = ();
my $data = "";

## SCHEMA TELLS ME HOW TO PROCES FEATURES
my $index =0;
while ($data = <schemafile>)
{
	chomp($data);
	my ($oldfeature,$processtype)=split(';',$data);
	$sheet_features[$index]= change_to_alphanumeric_lowercase($oldfeature);	
	#print "here $oldfeature $sheet_features[$index]\n";
	$postprocess[$index] = $processtype;
	$inverse_features{$sheet_features[$index]} = $index; 
	$index++;
}
close(schemafile);

if ($#ARGV < 1)
{
	die "usage: pclistsheettsv candidateconstraintsoutput\n";
}

open(pclist,"<$ARGV[0]") or die "cant open file $ARGV[0]\n";

open(out,">$ARGV[1]") or die "cant open output file\n";

my %new_features = ();
my @newdataset = ();
my @newnames = ();

## IGNORE LINE 1
my $data = <pclist>;

## GET TSV
my @fields = split(/\t/,$data);
my $lineindex = 0;
my %affiliations_names= ();
my %affiliations_counts = ();
while ($data = <pclist>)
{
	chomp($data);
	#print "here $data\n";
	my @fields = split(/\t/,$data);

	my $name =  change_to_alphanumeric_lowercase($fields[0]).change_to_alphanumeric_lowercase($fields[1]);		
	my $invite_preference =  $fields[5];
	my $reply_status =  $fields[6];
	if ( $reply_status eq "0"  or $reply_status eq "1" )
	{
		print out "$name,$reply_status\n";
	}
	elsif ($invite_preference eq "0"  or $invite_preference eq "1")
	{
		print out "$name,$invite_preference\n";
	}
}
close(pclist);

close(out);
