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

if ($#ARGV < 3)
{
	die "usage: pclistsheettsv groupconstraints groupthresh groupmax\n";
}

open(pclist,"<$ARGV[0]") or die "cant open file $ARGV[0]\n";
my $groupthresh = $ARGV[2];
my $groupmax = $ARGV[3];


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
	my $affiliation =  change_to_alphanumeric_lowercase($fields[2]);
	if (not defined $affiliations_counts{$affiliation})
	{
		$affiliations_counts{$affiliation} = 0;
	}
	$affiliations_counts{$affiliation}++;
	$affiliations_names{$affiliation}->{$name} = 1;

}
close(pclist);


## print outputfile in ezpc format

open(out,">$ARGV[1]");
my $key = "";
foreach $key (keys %affiliations_counts)
{
	if ($affiliations_counts{$key} >= $groupthresh)
	{
		print out "$key ";
		my $name = "";
		my $flag = 0;
		foreach $name (keys %{$affiliations_names{$key}})
		{	
			if ($flag == 0)
			{
				print out "$name";
				$flag = 1;
			}
			else
			{
				print out ",$name";
			}
		}
		print out " $groupmax\n";
	}	
}
