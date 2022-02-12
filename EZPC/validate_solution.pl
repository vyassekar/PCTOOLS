#! /usr/bin/perl

use strict;

use File::Slurp;


if ($#ARGV < 5)
{
	die "usage: inputcsvfile feature-coverage-constraintsfile solutionfiletocheck groupconstraints pcsizemin pcsizemaxe\n";
}


## read the config with 4 inputs -- policy, topology, mbox, switch
my $inputfile = $ARGV[0];
my $constraintsfile = $ARGV[1];
my $rowconstraintsfile = $ARGV[2];
my $groupconstraintsfile = $ARGV[3];
my $pcsizemin = $ARGV[4];
my $pcsizemax = $ARGV[5];

system("perl ezpc_solver.pl $inputfile $constraintsfile $rowconstraintsfile $groupconstraintsfile $pcsizemin $pcsizemax check_formulation.ilp check_solution.sol");


my $file_content = read_file('check_solution.sol');

if ($file_content =~/INTEGER\s+OPTIMAL/)
{
	print "Check passed\n";
}
elsif ($file_content =~/INTEGER\s+EMPTY/)
{
	print "Check failed, solution is not feasible\n";
}
else
{
	print "something wrong\n";
}

