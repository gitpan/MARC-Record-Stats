package MARC::Record::Stats;

use warnings;
use strict;
use version;

=head1 NAME

Marc::Record::Stats - scans one or many MARC::Record and gives a statistics on the tags and subtags

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = qv('0.0.1');


=head1 SYNOPSIS

    use Marc::Record::Stats;
    use Data::Dumper;
	...
	# single record statistics
	# $record is a MARC::Record
    my $stats1 = Marc::Record::Stats->new( $record );
    
    # many records statistics
    # $records is a reference to an array of MARC::Record
    my $stats2 = Marc::Record::Stats->new( $records, $stats1 );
    ...
    Data::Dumper->Dump([$stats1, $stats2],['stats1', 'stats2']);

=head1 METHODS

=head2 new $records [, $stats]

Builds statistics on $records, appends $stats if given.

=over 4

=item $records
A MARC::Record or a reference to an array of MARC::Record

=item $stats
Marc::Record::Stats object that contains accumulated statistics.

=back

=cut

sub new {
	my ($class, $records, $stats) = @_;
	
	my $self = {
		stats => { nrecords => 0 },
	};
	
	bless $self, $class;
	
	$self->_copy_stats($stats)
		if $stats;
	
	my $reclist = (ref $records eq 'ARRAY') ? $records : [ $records ];
	foreach my $rec ( @$reclist ) {
		$self->add_record_to_stats( $rec );
	}
	return $self;
}

=head2 get_stats_hash

Returns a hashref that contains the statistics:

	<stats_hash> = {
		nrecords	=> <int>, # the number of records
		tags		=> {
			<tag>	=> <tagstat>, # for every tag found in records
			...
		}
	}
	
	<tag>       = \d{3} # a tag, three digits
	
	<tag_stat>  = {
		occurence	=> <int>,			# how many records contain this tag
		subtags		=> <subtag_stat>,
	}
	
	<subtag_stat> = {
		<subtag>	=> {
			occurence	=> <int>,		# how many records contain this subtag
			repeatable  => <0|1>,       # whether or not is repeatable
		}
	}
	
	<subtag> = [a-z0-9] # alphanum, subtag

=cut

sub get_stats_hash { return $_[0]->{stats} }


=begin DEVELOPER

Deep copy of stats

=end DEVELOPER

=cut

sub _copy_stats {
	my ($self, $stats) = @_;
	my $stathash = $stats->get_stats_hash;
	my $selfstat = $self->get_stats_hash;
	
	$selfstat->{nrecords} = $stathash->{nrecords};
	foreach my $tag ( keys %{ $stathash->{tags} } ) {
		my $tagstat = $stathash->{tags}->{$tag};
		$selfstat->{tags}->{$tag}->{occurence} = $tagstat->{occurence};
		$selfstat->{tags}->{$tag}->{repeatable} = $tagstat->{repeatable};
		$selfstat->{tags}->{$tag}->{subtags} = { };
		foreach my $subtag ( keys %{ $tagstat->{subtags} } ) {
			$selfstat->{tags}->{$tag}->{subtags}->{$subtag}->{occurence} = $tagstat->{subtags}->{$subtag}->{occurence};
			$selfstat->{tags}->{$tag}->{subtags}->{$subtag}->{repeatable} = $tagstat->{subtags}->{$subtag}->{repeatable};
		} 
	}
}

=head2 add_record_to_stats $record 

Add record to statistics

=over 4

=item $record MARC::Record

=back

=cut

sub add_record_to_stats {
	my ($self, $record) = @_;
	
	return unless $record;
	
	my $stats = $self->get_stats_hash;
	
	$stats->{nrecords}++;
	
	my $record_stats = $self->get_record_stat($record);
	
	foreach my $tag ( keys %$record_stats ) {
		$stats->{tags}->{$tag}->{occurence}++;
		$stats->{tags}->{$tag}->{subtags} ||= {};
		
		$stats->{tags}->{$tag}->{repeatable} = 
			$record_stats->{$tag}->{occurence} > 1 ? 
			  1 : 0;
		
		my $subtag_stats = $stats->{tags}->{$tag}->{subtags};
		
		foreach my $subtag ( keys %{ $record_stats->{$tag}->{subtags} } ) {
			$subtag_stats->{$subtag}->{occurence}++;
			
			$subtag_stats->{$subtag}->{repeatable} =
				$record_stats->{$tag}->{subtags}->{$subtag} > 1 ?
				  1 : 0;
		}
	}
}

sub get_record_stat {
	my ($self, $record) = @_;
	my $stats;
	
	foreach my $field ( $record->fields ) {
		my $tag = $field->tag;
		
		$stats->{$tag}->{occurence}++;
			
		if( $tag > 9 ) {
			$stats->{$tag}->{subtags} =  $self->subtag_stats($field) || { };
		}
	}
	return $stats;
}

=head2 subtag_stats $field

returns <subtag_stat>

=over 4

=item $field MARC::Field

=back

=cut

sub subtag_stats {
	my ($self, $field) = @_;
	my $substat = { };
	
	foreach my $subtag ( $field->subfields ) {
		$substat->{ $subtag->[0] }++;
	}
	
	return $substat;
}

1; # End of Marc::Record::Stats
__END__
=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-marc-record-stats at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Marc-Record-Stats>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Marc::Record::Stats


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Marc-Record-Stats>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Marc-Record-Stats>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Marc-Record-Stats>

=item * Search CPAN

L<http://search.cpan.org/dist/Marc-Record-Stats/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Andrei V. Toutoukine.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

