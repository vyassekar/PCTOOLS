#! /usr/bin/perl

use strict;

sub print_set
{
	my $hashmap1 = shift;
	
	my $string  ="";
	my $key1 = "";
	my $flag = 0;
	foreach $key1 (sort keys %{$hashmap1})
	{
		if ($flag == 0)
		{
			$flag = 1;
			$string = "$key1";
		}
		else
		{
			$string = $string. ";$key1";
		}
	}
	return $string;
}


sub check_intersection
{
	my $hashmap1 = shift;
	my $hashmap2 = shift;
	my %intersection = ();
	my $intersection_size = 0;
	my $key1 = "";
	foreach $key1 (keys %{$hashmap1})
	{
		my $key2 = "";
		foreach $key2 (keys %{$hashmap2})
		{
			print "here checking $key1 $key2\n";
			if ($key1 eq $key2)
			{
				print "here found intersection $key1 $key2\n";
				$intersection{$key1} = 1;
				#	$intersection_size = $intersection_size _+ 1 ;
				$intersection_size = $intersection_size + 1;
			}
		}
	}
	return (\%intersection,$intersection_size);
}
sub  change_to_alphanumeric_lowercase
{
	my $input = shift;
	my $word = $input;
	$word =~ s/[^a-zA-Z0-9]+//g;
	$word = lc $word;
	return $word;
}


sub parse_authorsfile_get_affiliations
{
	my $filename = shift;
	my %map_papers_authors_and_affiliations = ();
	my %map_papers_rawinfo = ();
	open(f,"<$filename") or die "cant open authorsfile\n";
	my $data ="";
	$data = <f>;

	while ($data = <f>)
	{
		chomp($data);
		my @fields = split(/,/,$data);
		my $paperid = $fields[0];
		my $authornameorig = $fields[2].$fields[3];
		my $authorname = change_to_alphanumeric_lowercase($authornameorig);
		my $affiliationorig = $fields[5]; 
		my $affiliation = change_to_alphanumeric_lowercase($affiliationorig);
		if (not defined $map_papers_rawinfo{$paperid})
		{
			$map_papers_rawinfo{$paperid} = "$authornameorig ($affiliationorig)";
		}
		else
		{
			$map_papers_rawinfo{$paperid} = $map_papers_rawinfo{$paperid}.";$authornameorig ($affiliationorig)";
		}
		$map_papers_authors_and_affiliations{$paperid}->{$authorname} = 1;
		$map_papers_authors_and_affiliations{$paperid}->{$affiliation} = 1;
		#	print "here $paperid $affiliation\n";
		#<STDIN>;
	}
	close(f);
	return \%map_papers_authors_and_affiliations,\%map_papers_rawinfo;
}
sub parse_conflicts_file_per_paper
{
	my $filename = shift;
	my %map_papers_declared_conflicts = ();
	open(f,"<$filename") or die "cant open paper declared conflicts file\n";

	my $data ="";
	$data = <f>;
	while ($data = <f>)
	{
		chomp($data);
		my @fields = split(/,/,$data);
		my $paperid = $fields[0];
		my $pcname = $fields[2].$fields[3];
		my $conflicttype = $fields[5];
		$pcname = change_to_alphanumeric_lowercase($pcname);
		$map_papers_declared_conflicts{$paperid}->{$pcname} = $conflicttype;
	}
	close(f);
	return \%map_papers_declared_conflicts;


}
sub parse_pc_conflicts
{
	my $filename = shift;
	my %map_pcname_conflicts = ();
	open(f,"<$filename") or die "cant open pc declared conflicts file\n";
	my $data ="";
	$data = <f>;
	my $curpc = "";
	while ($data = <f>)
	{
		chomp($data);
		if ($data =~/\@/)
		{	
			my @fields = split(/,/,$data);
			$curpc = $fields[0].$fields[1];
			$curpc = change_to_alphanumeric_lowercase($curpc);
			$map_pcname_conflicts{$curpc}->{$curpc} = 1;
		}
		else
		{
			my $conflictnametmp= $data;
			my $conflictname= "";
			$conflictnametmp =~ s/\s+//g;
			if ($conflictnametmp =~ /All(.*)/)
			{
				$conflictname = $1;
				$conflictname = change_to_alphanumeric_lowercase($conflictname);
				$map_pcname_conflicts{$curpc}->{$conflictname} = 1;

			}	
			elsif ($conflictnametmp =~ /(.*)\(.*\)/)
			{
				$conflictname = $1;
				$conflictname = change_to_alphanumeric_lowercase($conflictname);
				$map_pcname_conflicts{$curpc}->{$conflictname} = 1;

			}	
			elsif ($conflictnametmp =~ /(.*)/)
			{
				$conflictname = $1;
				$conflictname = change_to_alphanumeric_lowercase($conflictname);
				$map_pcname_conflicts{$curpc}->{$conflictname} = 1;
			}	
			else
			{
				
				print "\t Not covered here $curpc $conflictnametmp\n";
				<STDIN>;
			}
		}
	}
	close(f);
	return \%map_pcname_conflicts;

}


if ($#ARGV < 3)
{
	die "usage: authorsfile conflictsfile pcfile spuriousfile missedfile spurioustsv missedtsv\n";
}

my $authorsfile = $ARGV[0];

my $conflictsfile = $ARGV[1];

my $pcfile = $ARGV[2];

my $spuriousfile = $ARGV[3];
my $spuriousfiletsv = $ARGV[5];

my $missedfile = $ARGV[4];
my $missedfiletsv = $ARGV[6];

my ($map_papers_authors_and_affiliations,$map_papers_rawinfo) = parse_authorsfile_get_affiliations($authorsfile);

my $map_papers_declared_conflicts =  parse_conflicts_file_per_paper($conflictsfile);

my $map_pcname_conflicts =  parse_pc_conflicts($pcfile);

## find spurious conflicts per paper

open(out1,">$spuriousfile") or die "cannot iopen file to write\n";
open(out2,">$spuriousfiletsv") or die "cannot open spreadsheet file to write\n";
my $paperid = "";
foreach $paperid (sort keys %{$map_papers_declared_conflicts})
{
	my $declared_pc = "";
	my $flag_paper = 0;
	my $flag_string = "";
	foreach $declared_pc (keys %{$map_papers_declared_conflicts->{$paperid}})
	{

		print "Checking $paperid $declared_pc\n";
		my ($intersection_set, $intersection_size) = check_intersection($map_papers_authors_and_affiliations->{$paperid}, $map_pcname_conflicts->{$declared_pc});
		if ($intersection_size == 0)
		{
			if ($flag_paper == 0)
			{
				$flag_string = $flag_string."\tPAPER declared conflict set:\n";
				$flag_string = $flag_string."\t\t".print_set($map_papers_authors_and_affiliations->{$paperid})."\n";
				$flag_paper = 1;
			}
			$flag_string = $flag_string."\tPCMEMBER=$declared_pc TYPEDECLARED= ".$map_papers_declared_conflicts->{$paperid}->{$declared_pc}."\n";
		       	$flag_string = $flag_string."\tFLAGGED PC MEMBER:$declared_pc declared conflicts:\n";
			my $pcstring = print_set($map_pcname_conflicts->{$declared_pc})."\n";
			my $intersectionprint = print_set($intersection_set);
			$flag_string = $flag_string."\t\t$pcstring";
			my $reasonclaimed = $map_papers_declared_conflicts->{$paperid}->{$declared_pc};
			my $paperinfo = $map_papers_rawinfo->{$paperid};
			print out2 "$paperid\t$declared_pc\t$paperinfo\t$reasonclaimed\n";

		}
	}
	if ($flag_paper == 1)
	{
		print out1 "FLAG Paper=$paperid\n";
		print out1 "$flag_string\n"; 

	}
}
close(out1);
close(out2);

## find missing conflicts


open(out1,">$missedfile") or die "cannot open file to write\n";
open(out2,">$missedfiletsv") or die "cannot open spreadsheet file to write\n";
my $paperid = "";
foreach $paperid (sort keys %{$map_papers_declared_conflicts})
{
	my $pcmember = "";
	my $flag_paper = 0;
	my $flag_string = "";
	foreach $pcmember (keys %{$map_pcname_conflicts})
	{
		if (not defined $map_papers_declared_conflicts->{$paperid}->{$pcmember})
		{
			print "Checking $paperid $pcmember\n";
			my ($intersection_set, $intersection_size) = check_intersection($map_papers_authors_and_affiliations->{$paperid}, $map_pcname_conflicts->{$pcmember});
			if ($intersection_size > 0)
			{
				$flag_string = $flag_string."\tPAPER declared conflict set:\n";
				$flag_string = $flag_string."\t\t".print_set($map_papers_authors_and_affiliations->{$paperid})."\n";
				$flag_paper = 1;
		  	     	$flag_string = $flag_string."\tFLAGGED PC MEMBER:$pcmember declared conflicts:\n";
				my $pcstring = print_set($map_pcname_conflicts->{$pcmember})."\n";
				$flag_string = $flag_string."\t\t$pcstring";
				print out1 "MISSED CONFLICT Paper=$paperid $pcmember\n";
				my $intersection_reason= print_set($intersection_set);
				$flag_string = $flag_string."REASON:\n\t\t$intersection_reason\n";
				print out1 "$flag_string\n"; 
				print out2 "$paperid\t$pcmember\t$intersection_reason\n";

			}
		}
	}
}
close(out1);
close(out2);

