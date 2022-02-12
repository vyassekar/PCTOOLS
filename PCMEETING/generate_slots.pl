#! /usr/bin/perl 

use strict;

my $numdays = 2;
my $slotsize = 15;

my $hourwrap = 60;
my $slotindex = 0;

my $current_day =1;


for ($current_day = 1; $current_day <= $numdays; $current_day++)
{
	my $starttime_hour = 10;
	my $endtime_hour = 19;
	my $endtime_mins = 0;
	my $starttime_mins = 0;
	my $flag  =0;

	my $current_hour = $starttime_hour;
	my $current_mins = $starttime_mins;
	while ($flag == 0)
	{
		$slotindex++;

		my $next_hour = ($current_mins == ($hourwrap-$slotsize))? ($current_hour +1):$current_hour;
		my $next_mins = ($current_mins == ($hourwrap-$slotsize))? 0:$current_mins+$slotsize;
		my $current_slot = sprintf("%02d_%02d_%02d_%02d_%02d",$current_day,$current_hour,$current_mins,$next_hour,$next_mins);	
		print "$current_slot $slotindex\n";
		$current_mins += $slotsize;
		if ($current_mins == $hourwrap)
		{
			$current_mins = 0;
			$current_hour++;
			
		}
		if ($endtime_hour == $current_hour)
		{
			$flag =1;
		}

	}

}
