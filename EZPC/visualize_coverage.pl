#! /usr/bin/perl

use strict;

if ($#ARGV < 2)
{
	die "usage: inputfeaturesfile candidatesselected visualizesolution\n";
}


## read the config with 4 inputs -- policy, topology, mbox, switch
my $inputfile = $ARGV[0];
my $rowconstraintsfile = $ARGV[1];
my $outfile = $ARGV[2];

system("dos2unix $inputfile");
open (f,"<$inputfile") or die "Cant read configfile\n";

my $firstline = <f>;
chomp($firstline);
my @featurenames = split(/,/,$firstline);

my %feature_constraints = ();
my %candidates_features = ();
my %features_candidates = ();

my %featurescountcandidates = ();
my %candidates_index= ();
my %index_candidates= ();


my $data = "";
my $numcandidates = 0;
while ($data = <f>)
{
	chomp($data);
	my @candidate_fields = split(/,/,$data);
	my $candidate_name = $candidate_fields[0];
	$candidate_name =~  s/\s+//g;
	if ($candidate_name =~ /\w/)
	{
	$candidates_index{$candidate_name} = $numcandidates;
	$index_candidates{$numcandidates} = $candidate_name;
	my $j = 0;
	for ($j =1; $j <= $#candidate_fields; $j++)
	{
		my $featurename = $featurenames[$j];
			
		if ( ($candidate_fields[$j] == 1) or ($candidate_fields[$j] eq "x"))
		{
			$candidates_features{$candidate_name}->{$featurename}  =1;
			$features_candidates{$featurename}->{$candidate_name}  =1;
			$featurescountcandidates{$featurename}++;
		} 
	}
	$numcandidates++;
	}
}
close(f);


		

my %candidate_selected = ();
open (f,"<$rowconstraintsfile") or die "Cant read configfile\n";
my $data = "";
while ($data = <f>)
{
	chomp($data);
	my @constraints = split(/,/,$data);
	my $candidate_name = $constraints[0];
	$candidate_name =~  s/\s+//g;
	if ($constraints[1] == 1)
	{
		$candidate_selected{$candidate_name} = $constraints[1];
	}
}
close(f);


open(out,">$outfile");

## per feature coverage
my $feature = "";
foreach $feature (sort keys %features_candidates)
{
	print out "$feature;";
	my $candidate = "";
	my $count = 0;
	foreach $candidate (keys %{$features_candidates{$feature}})
	{	
		if ($candidate_selected{$candidate})
		{
			$count++;		
		}
	}
	print out "$count;";
	my $flag = 0;
	
	foreach $candidate (keys %{$features_candidates{$feature}})
	{	
		if ($candidate_selected{$candidate})
		{
			print out " $candidate";
		}
	}
	print out "\n";
}

