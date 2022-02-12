#! /usr/bin/perl

use strict;

if ($#ARGV < 7)
{
	die "usage: inputfeaturesfile feature-coverage-constraintsfile candidate-availability-constraintsfile groupconstraints pcsizemin pcsizemax formulationfile solutionfile\n";
}


## read the config with 4 inputs -- policy, topology, mbox, switch
my $inputfile = $ARGV[0];
my $constraintsfile = $ARGV[1];
my $rowconstraintsfile = $ARGV[2];
my $groupconstraintsfile = $ARGV[3];
my $pcsizemin = $ARGV[4];
my $pcsizemax = $ARGV[5];
my $formulationfile = $ARGV[6];
my $solutionfile = $ARGV[7];

#system("dos2unix $inputfile");
open (f,"<$inputfile") or die "Cant read configfile $inputfile\n";

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

		

open (f,"<$constraintsfile") or die "Cant read configfile $constraintsfile\n";
my $firstline = <f>;
while ($data = <f>)
{
	chomp($data);
	my @constraints = split(/,/,$data);
	$feature_constraints{$constraints[0]}->{"min"} = $constraints[1];
	$feature_constraints{$constraints[0]}->{"max"} = $constraints[2];
}
close(f);


my %candidate_constraints = ();
open (f,"<$rowconstraintsfile") or die "Cant read configfile $rowconstraintsfile\n";
my $data = "";
while ($data = <f>)
{
	chomp($data);
	my @constraints = split(/,/,$data);
	my $candidate_name = $constraints[0];
	$candidate_name =~  s/\s+//g;
	if ( ($constraints[1] ne "x"  ) and ( ($constraints[1] == 0)  or ($constraints[1] == 1)) )
	{
		$candidate_constraints{$candidate_name} = $constraints[1];
		#	print "Here constrained cand $candidate_name\n";

	}
}
close(f);




my $selectedvar = "d"; 

open(out1,">$formulationfile") or die "cant open $formulationfile\n";

print out1 "Minimize\n Cost:   ";

for (my $i  =0; $i < $numcandidates; $i++)
{
	my $thiscoveragevar ="$selectedvar"."_$index_candidates{$i}";	
	if ($i == 0)
	{
		print out1 "$thiscoveragevar";
	}
	else
	{
		print out1 " + $thiscoveragevar";
	}
}
print out1 " \n";


print out1 "Subject To\n";


## Number of members to select 
my $class = "";
print out1 "TOTALPCSIZEMAX: ";
for (my $i  =0; $i < $numcandidates; $i++)
{
	my $thiscoveragevar ="$selectedvar"."_$index_candidates{$i}";	
	if ($i == 0)
	{
		print out1 "$thiscoveragevar";
	}
	else
	{
		print out1 " + $thiscoveragevar";
	}
}
print out1 "  <= $pcsizemax\n";


print out1 "TOTALPCSIZEMIN: ";
for (my $i  =0; $i < $numcandidates; $i++)
{
	my $thiscoveragevar ="$selectedvar"."_$index_candidates{$i}";	
	if ($i == 0)
	{
		print out1 "$thiscoveragevar";
	}
	else
	{
		print out1 " + $thiscoveragevar";
	}
}
print out1 "  >= $pcsizemin\n";


## per feature constraints

my $feature = "";
foreach $feature (keys %feature_constraints)
{
	if (defined $featurescountcandidates{$feature} )
	{
	
	my $min = $feature_constraints{$feature}->{"min"};
	print out1 "FEATUREMIN.$feature: ";
	my $candidate = "";
	my $flag = 0;
	foreach $candidate (keys %{$features_candidates{$feature}})
	{	
		my $index = $candidates_index{$candidate};
		my $thiscoveragevar ="$selectedvar"."_$candidate";	
		if ($flag == 0)
		{
			print out1 "$thiscoveragevar";
			$flag = 1;

		}
		else
		{
			print out1 " + $thiscoveragevar";
		}
	}
	print out1 " >= $min\n"; 
	my $max = $feature_constraints{$feature}->{"max"};
	print out1 "FEATUREMAX.$feature: ";
	my $candidate = "";
	my $flag = 0;
	foreach $candidate (keys %{$features_candidates{$feature}})
	{	
		my $index = $candidates_index{$candidate};
		my $thiscoveragevar ="$selectedvar"."_$candidate";	
		if ($flag == 0)
		{
			print out1 "$thiscoveragevar";
			$flag = 1;
		}
		else
		{
			print out1 " + $thiscoveragevar";
		}
	}
	print out1 " <= $max\n"; 
	}

	else

	{
		print "WARNING: No coverage possible for $feature .. Ignoring and proceeding!\n";
	}
}

## per candidate constraints
my $candidate = "";
foreach $candidate (keys %candidate_constraints)
{
	my $thiscoveragevar ="$selectedvar"."_$candidate";	
	print out1 "CANDIDATE.$candidate:  $thiscoveragevar = $candidate_constraints{$candidate}\n";
}

## Candidate group constraints

open (f,"<$groupconstraintsfile") or die "Cant read configfile $groupconstraintsfile\n";
my $groupid = 1;
while ($data = <f>)
{
	chomp($data);
	my ($constname, $names,$max) = split(/\s+/,$data);
	my @people = split(/,/,$names);
	print out1 "GROUPCONST.$constname: ";
	my $flag = 0;
	foreach $candidate (@people)
	{
		my $thiscoveragevar ="$selectedvar"."_$candidate";	
		if ($flag ==0 )
		{
			print out1 "  $thiscoveragevar ";
			$flag = 1;
		}	
		else
		{
			print out1 " +  $thiscoveragevar ";

		}
	}
	print out1 " <= $max\n";
	$groupid++;
}
close(f);



	

print out1 "Binaries\n";

my $class = "";
for (my $i  =0; $i < $numcandidates; $i++)
{
	my $thisactivevar ="$selectedvar"."_$index_candidates{$i}";	
	print out1 "$thisactivevar\n";
}


print out1 "End\n";
close(out1); 

system(" glpsol --lp $formulationfile -o $solutionfile");
