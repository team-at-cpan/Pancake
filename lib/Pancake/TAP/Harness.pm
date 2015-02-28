package Pancake::TAP::Harness;

use strict;
use warnings;

use parent qw(TAP::Harness);

use Pancake::TAP::Formatter;
use Pancake::TAP::Formatter::Session;

use Data::Dumper;

sub new {
	my ($class, $args) = @_;
	die "extra? @_" if @_ > 2;
#	warn "Created with " . Dumper($args);
	$args->{formatter_class} //= 'Pancake::TAP::Formatter';
	my $self = $class->SUPER::new($args);
	$self
}

1;

