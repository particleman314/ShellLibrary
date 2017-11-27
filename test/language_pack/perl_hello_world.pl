##
## Hello World for Perl
##

my $prefix = "\t";
if ( exists $ENV{'SLCF_DETAIL'} && $ENV{'SLCF_DETAIL'} != 0 ) {
    $prefix="$ENV{'SLCF_PREFIX_DETAIL'}";
}

print STDOUT "$prefix  Hello World.  Running Perl from the Shell Test Harness ( part of the Shell Library Component Framework )\n";
