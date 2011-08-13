#!/usr/bin/env perl
use warnings;
use strict;

use MARC::Record::Stats;
use MARC::File::USMARC;

use Getopt::Euclid;

my $stats = MARC::Record::Stats->new();

foreach my $fn ( @{ $ARGV{'<file>'} } ) {
	my $batch = MARC::File::USMARC->in( $fn )
		or warn "Can't read the file $fn\n";
	next unless $batch;
	
	while ( my $record = $batch->next() ) {
		$stats->add_record_to_stats($record);
	}
	
	$batch->close();
	undef $batch;
}

my $out;
if ( my $fn = $ARGV{'-o'} ) {
	open $out, ">", "$fn";
}
else {
	$out = *STDOUT
}

report($out, $stats->get_stats_hash);

if ( $ARGV{'-o'} ) { close $out; }

# TODO should be somewhere in modules
sub report{
	my ($FH, $hash) = @_;
	my @lines;
	my $nrecords = $hash->{nrecords};
	
	foreach my $tag ( sort keys %{$hash->{tags}} ) {
		my $tagstat = $hash->{tags}->{$tag};
		my $is_repeatable = $tagstat->{repeatable} ? '[Y]' : '   ';
		my $occurence = sprintf("%6.2f",100*$tagstat->{occurence}/$nrecords);
		push @lines, "$tag     $is_repeatable     $occurence";
		
		foreach my $subtag ( sort keys %{ $tagstat->{subtags} } ) {
			my $subtagstat = $tagstat->{subtags}->{$subtag};
			my $occurence = sprintf("%6.2f",100.0*$subtagstat->{occurence}/$nrecords);
			my $is_repeatable = $tagstat->{repeatable} ? '[Y]' : '   ';
			push @lines, "   $subtag    $is_repeatable     $occurence";
		}
		 
	}
	
	if ( $ARGV{'--dots'} ) {		
		@lines = map { s/\s/./g; $_ } @lines;
	}
	
	unshift @lines, "Tag     Rep.    Occ.,%";
	unshift @lines, "Statistics for $nrecords records";
	
	
	
	print $FH join ("\n",@lines), qq{\n\n};
	
}
=head1 NAME

marcstats.pl - collect statistics for MARC records

=head1 USAGE

	marcstats.pl [options] <file>,...

=head1 VERSION

This documentation is for marcstats.pl version 0.0.1

=head1 REQUIRED ARGUMENTS

=over

=item <file>

Name(s) of the MARC batch file(s). Several file names may be given:

	marcstat.pl -o statistics.txt batch1.iso batch2.iso --dots

=for Euclid:
	repeatable

=back

=head1 OPTIONS

=over

=item --dots

Replace spaces with dots in the output

=item -o <outfile>

Send output to outfile

=back

=cut