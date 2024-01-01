#!/usr/bin/env perl
#####
# keywords.pl
# Andy Hammerlindl 2006/07/31
#
#  Extract keywords from camp.l and list them in a keywords file.  These
#  keywords are used in autocompletion at the interactive prompt.
#####

use strict;
use warnings;

use Getopt::Long;

my $camplfile;
my $output_keywords_file;
my $process_file;

GetOptions(
    "camplfile=s"    => \$camplfile,
    "output=s"       => \$output_keywords_file,
    "process-file=s" => \$process_file
) || die("Argument error");

# Extra keywords to add that aren't automatically extracted, currently none.
my @extrawords = ();


open(my $keywords, ">$output_keywords_file") ||
    die("Couldn't open $output_keywords_file for writing.");

print $keywords <<END;
/*****
 * This file is automatically generated by keywords.pl.
 * Changes will be overwritten.
 *****/

END

sub add {
  print $keywords "ADD(".$_[0].");\n";
}

foreach my $word (@extrawords) {
  add($word);
}
open(my $camp, $camplfile) || die("Couldn't open $camplfile");

# Search for the %% separator, after which the definitions start.
while (<$camp>) {
  if (/^%%\s*$/) {
    last; # Break out of the loop.
  }
}

# Grab simple keyword definitions from camp.l
while (<$camp>) {
  if (/^%%\s*$/) {
    last; # A second %% indicates the end of definitions.
  }
  if (/^([A-Za-z_][A-Za-z0-9_]*)\s*\{/) {
    add($1);
  }
}

# Grab the special commands from the interactive prompt.
open(my $process, $process_file) || die("Couldn't open $process_file");

while (<$process>) {
  if (/^\s*ADDCOMMAND\(\s*([A-Za-z_][A-Za-z0-9_]*),/) {
    add($1);
  }
}

close($process);
close($keywords);
close($camp);