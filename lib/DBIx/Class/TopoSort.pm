package DBIx::Class::TopoSort;

use 5.008_004;

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.0400001';

use Graph;

sub toposort_graph {
  my $self = shift;
  my (%opts) = @_;

  my $g = Graph->new;

  my @source_names = $self->sources;

  my %table_source = map { 
    $self->source($_)->name => $_
  } @source_names;

  foreach my $name ( @source_names ) {
    my $source = $self->source($name);
    $g->add_vertex($name);

    foreach my $rel_name ( $source->relationships ) {
      next if grep { $_ eq $rel_name } @{$opts{skip}{$name}};
      my $rel_info = $source->relationship_info($rel_name);

      if ( $rel_info->{attrs}{is_foreign_key_constraint} ) {
        $g->add_edge(
          $table_source{$self->source($rel_info->{source})->name},
          $name,
        );
      }
    }
  }

  return $g;
}

sub toposort {
  my $self = shift;

  my ($g, @rv);
  eval {
    $g = $self->toposort_graph(@_);
    @rv = $g->toposort();
  }; if ($@) {
    if ($g) {
      my @c = $g->find_a_cycle;
      if (@c) {
        warn "Cycle found: '" . join("' -> '", @c) . "'\n";
      }
    }
    die $@;
  }

  return @rv;
}

1;
__END__

=head1 NAME

DBIx::Class::TopoSort - The addition of topological sorting to DBIx::Class

=head1 SYNOPSIS

Within your schema class:

  __PACKAGE__->load_components('TopoSort');

Later:

  my $schema = Your::App::Schema->connect(...);
  my @toposorted_sourcenames = $schema->toposort();

If you have a cycle in your relationships

  my @toposorted_sourcenames = $schema->toposort(
      skip => {
          Artist => [qw/ first_album /],
      },
  );

=head1 DESCRIPTION

This adds a method to L<DBIx::Class::Schema> which returns the full list of
sources (similar to L<DBIx::Class::Schema/sources>) in topological-sorted order.

=head2 TOPOLOGICAL SORT

A topological sort of the tables returns the list of tables such that any table
with a foreign key relationship appears after any table it has a foreign key
relationship to.

=head1 METHODS

This class is not instantiable nor does it provide any methods of its own. All
methods are added to the L<DBIx::Class::Schema> class and are callable on
objects instantiated of that class.

=head2 toposort

This is sugar for:

  $self->toposort_graph(@_)->toposort();

Calling this method multiple times may return the list of source names in
different order. Each order will conform to the gurantee described in the
section on TOPOLOGICAL SORT.

This method will throw an error if there are any cycles in your tables. You will
need to specify the skip parameter (described below) to break those cycles.

=head2 toposort_graph

This returns a L<Graph> object with a vertex for every source and an edge for
every foreign key relationship.

It takes the following parameters.

=over 4

=item skip

This describes the list of relationships that should be ignored by the toposort
algorithm. This is generally used if you have cycles in your schema (though it
could possibly be useful in other ways, I guess). The value is a hashref. The
keys of this hashref are source names and the values are arrays of relationship
names.

  skip => {
      Artist => [ qw/ first_album / ],
  },

=back

=head1 SEE ALSO

L<Graph/toposort>

=head1 AUTHOR

=over 4

=item * Rob Kinyon <rob.kinyon@gmail.com>

=back

=head1 LICENSE

Copyright (c) 2013 Rob Kinyon. All Rights Reserved.
This is free software, you may use it and distribute it under the same terms
as Perl itself.

=cut