package Pancake::TAP::Formatter::Session;

use strict;
use warnings;

use parent qw(TAP::Formatter::Session);

use Time::HiRes;
use Data::Dumper;

sub new {
	my ($class, $args) = @_;
	my $fh = delete $args->{outfh};
	my $self = $class->SUPER::new($args);
	$self->{outfh} = $fh;
	$self
}

sub result {
	my ($self, $result) = @_;
	$self->{outfh}->print(join(':', "TAP", $self->name, Time::HiRes::time - $self->parser->start_time, $result->raw) . "\n");
#	warn "result: " . Dumper($result) . "\n";
}

sub close_test {
	my ($self, @args) = @_;
	$self->{outfh}->print(join(':', "close", $self->name, Time::HiRes::time) . "\n");
	$self->SUPER::close_test(@args);
}

1;
