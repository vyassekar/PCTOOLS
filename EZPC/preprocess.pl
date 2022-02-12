#! /usr/bin/perl
#
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
	die "usage: pclistsheettsv outputcsv\n";
}

open(pclist,"<$ARGV[0]") or die "cant open file $ARGV[0]\n";


my %new_features = ();
my @newdataset = ();
my @newnames = ();

## IGNORE LINE 1
my $data = <pclist>;

## GET TSV
my @fields = split(/\t/,$data);
my $lineindex = 0;
while ($data = <pclist>)
{
	chomp($data);
	#print "here $data\n";
	my @fields = split(/\t/,$data);
	my $rowmerged = "";
	for (my $i = 0; $i <= $#fields; $i++)
	{
		my $featuretype = $postprocess[$i];
		my $value = change_to_alphanumeric_lowercase($fields[$i]);			
		my $newfeature = "";
		if ($featuretype eq "IGNORE")
		{
			## ignore this feature dont do anything
		}
		elsif ($featuretype =~ /ROWMERGE-(\w+)/)
		{
			$rowmerged = $rowmerged.$value;
		}
		else
		{
			if ($featuretype eq "EXPAND")
			{
				$newfeature = $sheet_features[$i]."_"."$value";	
				#	print "$data: HERE $sheet_features[$i] value = $value\n";
			}
			elsif ($featuretype eq "BINARYCOL")
			{
				$newfeature = $sheet_features[$i];	
			}
			if (not defined $new_features{$newfeature} )
			{
				$new_features{$newfeature} = 1;
				#print "adding new feature $newfeature\n"; 
				if ($newfeature !~ /\w+/)
				{
					print "Error: $data\n";
					die;
				}
			}
			## make this into a binary feature
			if ($value =~ /\w+/ or $value eq 1)
			{
				$newdataset[$lineindex]->{$newfeature} =1;
				#print "$rowmerged $newfeature ACTIVE\n"; 
			}
		} 
	}
	$newnames[$lineindex] = $rowmerged;
	$lineindex++;
}
close(pclist);


## print outputfile in ezpc format

open(out,">$ARGV[1]");
print out "Name";
my $key = "";
foreach $key (sort keys %new_features)
{
	print out ",$key";
}
print out "\n";

## print binary encoding of values 
for (my $row =0; $row <= $#newdataset; $row++)
{
	print out "$newnames[$row]";
	foreach $key (sort keys %new_features)
	{
		if (defined $newdataset[$row]->{$key})
		{
			print out ",1";
		}
		else
		{
			print out ",0";
		}	
	}
	print out "\n";
}

close(out);
