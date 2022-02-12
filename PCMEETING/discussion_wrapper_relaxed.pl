#! /usr/bin/perl

use strict;

sub  change_to_alphanumeric_lowercase
{
	my $input = shift;
	my $word = $input;
	$word =~ s/[^a-zA-Z0-9]+//g;
	$word = lc $word;
	return $word;
}

if ($#ARGV < 4)
{
	die "usage: PCASSIGNMENTSFILEFORDISCUSS ALLSLOTS BREAKSLOTS NONAVAILABILITY  FORMULATIONFILE\n";
}

## read pc discussion file 
#
my $pcdiscussfile = $ARGV[0];
my $allslotsfile = $ARGV[1];
my $breakslotsfile = $ARGV[2]; 
my $nonavailfile = $ARGV[3];
my $formulationfile = $ARGV[4];
#
open(f,"<$pcdiscussfile") or die "Cant open pc discuss file\n";
my %is_reviewer_for_paper = ();
my %reviewers_for_paper  = ();
my $data = "";
while ($data = <f>)
{
	chomp($data);
	if ($data !~ /clearreview/ and $data !~ /action/)
	{
		my @fields = split(",",$data);
		my $paperid = $fields[0];
		my $reviewer = change_to_alphanumeric_lowercase($fields[2]);
		$is_reviewer_for_paper{$reviewer}->{$paperid}= 1;
		$reviewers_for_paper{$paperid}->{$reviewer}= 1;
	}
}
close(f);

## read slots file 

open(f,"<$allslotsfile") or die "Cant open slots file\n";
my %slotindex = ();
while ($data = <f>)
{
	chomp($data);
	my @fields = split(/\s+/,$data);
	my $slotid = $fields[0];
	$slotindex{$slotid} = $fields[1];
}
close(f);

## read break slots file 

open(f,"<$breakslotsfile") or die "Cant open slots file\n";
my %breakslot = ();
while ($data = <f>)
{
	chomp($data);
	my @fields = split(/\s+/,$data);
	my $slotid = $fields[0];
	$breakslot{$slotid} = 1;
}
close(f);



## read non availability file
open(f,"<$nonavailfile") or die "Cant open avail file\n";
my %not_available_for_by_reviewer = ();
my %has_constraints = ();
my %not_available_for_by_slot = ();
my $reviewer ="";
while ($data = <f>)
{
	chomp($data);
	if ($data =~ /REV\s+(.*)/)
	{
		$reviewer = change_to_alphanumeric_lowercase($1);
		$has_constraints{$reviewer} = 1;
	}
	else
	{
		my $slot = $data;
		$not_available_for_by_reviewer{$reviewer}->{$slot} = 1;
		$not_available_for_by_slot{$slot}->{$reviewer} = 1;
	}
}
close(f);




## CONSTRAINTS
#
my $selectedvar = "d"; 

open(out1,">$formulationfile") or die "cant open $formulationfile\n";

print out1 "Minimize\n Cost:  MaxSlot + 20 MaxMissingCoverage \n";


print out1 "Subject To\n";

## At most one paper per slot
my $slot = "";
foreach $slot (keys %slotindex)
{
	print out1 "PerSlotConstraint_$slot: ";
	my $flag =0;
	my $paperid = "";
	foreach $paperid (keys %reviewers_for_paper)
	{
		my $thiscoveragevar ="$selectedvar"."_$paperid"."_".$slot;	
		if ($flag == 0)
		{
			$flag = 1;
			print out1 "$thiscoveragevar";
		}
		else
		{
			print out1 "+ $thiscoveragevar ";
		}
	}	
	print out1 " <= 1\n";
}

## Each paper is covered in exactly 1 slot
#
my $paperid = "";
foreach $paperid (keys %reviewers_for_paper)
{

	print out1 "PerPaperConstraint_$paperid: ";
	my $flag =0;
	my $slot = "";
	foreach $slot (keys %slotindex)
	{
		my $thiscoveragevar ="$selectedvar"."_$paperid"."_".$slot;	
		if ($flag == 0)
		{
			$flag = 1;
			print out1 "$thiscoveragevar";
		}
		else
		{
			print out1 "+ $thiscoveragevar ";
		}
	}	
	print out1 " = 1\n";
}

## assignment variables satisfy reviewer availability -- relax to model coverage 
#
my $paperid = "";
foreach $paperid (keys %reviewers_for_paper)
{

	print out1 "Coverage_Constraint_$paperid: Coverage_$paperid ";

	my $slot = "";
	foreach $slot (keys %slotindex)
	{
		my $reviewer = "";
		my $thiscoveragevar ="$selectedvar"."_$paperid"."_".$slot;	
		my $numavailable = 0;
		foreach $reviewer (keys %{$reviewers_for_paper{$paperid}})
		{
			if (not defined $not_available_for_by_reviewer{$reviewer}->{$slot})	
			{
				$numavailable++;
			}
		}
		print out1 " - $numavailable $thiscoveragevar";
	}
	print out1 " = 0\n";
}

## model max missing coverage
my $paperid = "";
foreach $paperid (keys %reviewers_for_paper)
{

	print out1 "Missing_Coverage_Constraint_$paperid: MaxMissingCoverage  + Coverage_$paperid >= 5\n";

}


## break slots no assignment 
my $paperid = "";
foreach $paperid (keys %reviewers_for_paper)
{
	my $slot = "";
	foreach $slot (keys %breakslot)
	{
		my $thiscoveragevar ="$selectedvar"."_$paperid"."_".$slot;	
		print out1 "Break_Constraint_$paperid.$slot: $thiscoveragevar = 0\n";
	}
}

## 
#
# Model usage and cost
my $slot = "";
foreach $slot (keys %slotindex)
{
	print out1 "IsUsedConstraint_$slot: ";
	my $flag =0;
	my $paperid = "";
	my $usedvar  = "u_$slot";
	foreach $paperid (keys %reviewers_for_paper)
	{
		my $thiscoveragevar ="$selectedvar"."_$paperid"."_".$slot;	
		if ($flag == 0)
		{
			$flag = 1;
			print out1 "$thiscoveragevar";
		}
		else
		{
			print out1 "+ $thiscoveragevar ";
		}
	}	
	print out1 " - $usedvar <= 0\n";

	my $slotnum = $slotindex{$slot};
	print out1 "MaxModelConstraint_$slot: MaxSlot - $slotnum  $usedvar >= 0\n";
}

	
print out1 "Binaries\n";
my $paperid = "";
foreach $paperid (keys %reviewers_for_paper)
{
	foreach $slot (keys %slotindex)
	{
		my $thiscoveragevar ="$selectedvar"."_$paperid"."_".$slot;	
		print out1 "$thiscoveragevar\n";
	}
}
print out1 "End\n";
close(out1); 


