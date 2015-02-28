package Pancake::TAP::Formatter;

use strict;
use warnings;

use parent qw(TAP::Formatter::Base);

use Pancake::TAP::Formatter::Session;
# TAP::Formatter::Console
use IO::Handle;

sub new {
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);
	$self->{outfh} ||= do {
		my $io = IO::Handle->new;
		warn "no handle success" and sleep 10 unless $io->fdopen(3, 'w');
		$io
	};
	$self
}

sub open_test {
    my ( $self, $test, $parser ) = @_;

    my $class = 'Pancake::TAP::Formatter::Session';

	$self->{outfh}->print(join(':', "start", $test, Time::HiRes::time) . "\n");
    my $session = $class->new({
		name       => $test,
		formatter  => $self,
		parser     => $parser,
		show_count => $self->show_count,
		outfh      => $self->{outfh},
	});

    $session->header;
    return $session;
}

sub _output_success {
    my ( $self, $msg ) = @_;
    $self->_output($msg);
}

sub _failure_output {
    my $self = shift;
    my $out = join '', @_;
    my $has_newline = chomp $out;
    $self->_output($out);
    $self->_output($/)
      if $has_newline;
}

sub _output {
	my ($self, $out) = @_;
	chomp $out;
	warn "output => $out\n";
}

1;
