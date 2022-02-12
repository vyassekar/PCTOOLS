#! /usr/bin/perl

use strict;

if ($#ARGV < 3)
{
	die "usage: TSVFILE SUFFIXFORFILES MINPC MAXPC\n";
}


## read the config with 4 inputs -- policy, topology, mbox, switch
my $input_tsv_file = $ARGV[0];
my $suffix_to_use = $ARGV[1];
my $minpc = $ARGV[2];
my $maxpc = $ARGV[3];


print "Running perl preprocess.pl $input_tsv_file ilpinput_$suffix_to_use.csv\n";
system("perl preprocess.pl $input_tsv_file ilpinput_$suffix_to_use.csv");
print "Running perl generate_group_constraints.pl $input_tsv_file constraints_group_$suffix_to_use.txt 4 10\n";
system("perl generate_group_constraints.pl $input_tsv_file constraints_group_$suffix_to_use.txt 4 10");
print "Running perl generate_candidate_constraints.pl $input_tsv_file constraints_candidates_$suffix_to_use.csv\n";
system("perl generate_candidate_constraints.pl $input_tsv_file constraints_candidates_$suffix_to_use.csv");
print "perl ezpc_solver.pl ilpinput_$suffix_to_use.csv constraints_features_$suffix_to_use.csv constraints_candidates_$suffix_to_use.csv constraints_group_$suffix_to_use.txt $minpc $maxpc formulation_$suffix_to_use.ilp solution_$suffix_to_use.txt\n";
system("perl ezpc_solver.pl ilpinput_$suffix_to_use.csv constraints_features_$suffix_to_use.csv constraints_candidates_$suffix_to_use.csv constraints_group_$suffix_to_use.txt $minpc $maxpc formulation_$suffix_to_use.ilp solution_$suffix_to_use.txt");
print "Running perl extract_solution.pl solution_$suffix_to_use.txt picked_$suffix_to_use.txt dropped_$suffix_to_use.txt\n";
system("perl extract_solution.pl solution_$suffix_to_use.txt picked_$suffix_to_use.txt dropped_$suffix_to_use.txt");
