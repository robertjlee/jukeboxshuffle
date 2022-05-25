#!/usr/bin/perl

use warnings;
use strict;

# number of runs
my $numruns = 50000;
# size of array to shuffle
my $max = 50;
# target number (how close is a clump)
my $target = 1;

my @values;
my @results;
my ($i,$j);


# swap two entries by index
sub swap {
    my $i = shift;
    my $j = shift;
    my $t = $values[$i];
    $values[$i] = $values[$j];
    $values[$j] = $t;
}

# Count the number of adjacent entries
sub countadj {
    my $rtn=0;
    for $i (1..$max-1) {
	$rtn++ if abs($values[$i] - $values[$i+1]) < $target;
    }
    $rtn;
}

# algorithm to test; returns number of adjacent entries left
sub myshuffle {
    my $numforward = shift;
    my $numreverse = shift;
    
    # initialise the array
    for $i (0..$max+1) {
	$values[$i] = $i;
    }

    # Fisher-Yates shuffle
    for $i (1..$max-1) {
	$j = $i+1+int(rand($max-$i));
	swap($i,$j);
    }

    # forward pass
    my $pass;
    for $pass (1..$numforward) {
	for $i (1..$max-2) {
	    if (abs($values[$i] - $values[$i+1]) < $target) {
		$j = $i+2+int(rand($max-$i-1));
		swap($i+1,$j);
	    }
	}
    }

    # reverse pass
    for $pass (1..$numreverse) {
	for $i (reverse(1..$max-2)) {
	    if (abs($values[$i]- $values[$i+1]) < $target) {
		$j = 1+int(rand($i-1));
		swap($i,$j);
	    }
	}
    }

    countadj
}



sub res {
    print shift, $#results;
    if (scalar(@results) == 0) {
	print "\n--Clean--\n";
    } else {
#	print "\ncount of non-zero results per run: @results\n";
	@results = sort @results;
	print "Min/max: $results[0]/$results[$#results-1]\n";
	print "% fail: ", 100*(scalar @results)/$numruns, "\n";
    }
}

print "Results for $numruns runs with array of $max entries; target=$target\n";
print "-----\n\n";

@results = ();
for (1..$numruns) {
    my $t = myshuffle(1,0);
    if ($t > 0) {
	push @results, $t;
    }
}
res("single forward ");

@results = ();
for (1..$numruns) {
    my $t = myshuffle(2,0);
    push @results, $t if $t > 0;
}
res("\ndouble forward ");

@results = ();
for (1..$numruns) {
    my $t = myshuffle(1,1);
    push @results, $t if $t > 0;
}
res("\nforward & back ");
