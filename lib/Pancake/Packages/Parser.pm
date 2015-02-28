package Pancake::Packages::Parser;

use strict;
use warnings;

use parent qw(IO::Async::Notifier);

use IO::Async::Stream;
use IO::Async::Process;

use Log::Any qw($log);

use Mixin::Event::Dispatch::Bus;

sub bus { shift->{bus} //= Mixin::Event::Dispatch::Bus->new }

sub configure {
	my ($self, %args) = @_;
	if(exists $args{source}) {
		$self->{source} = delete $args{source};
	}
	$self->SUPER::configure(%args);
}

sub source { shift->{source} }
sub use_zcat { 1 }

sub header {
	my ($self, $k) = @_;
	return $self->{header}{$k} // die "no header $k"
}
sub process_future { $_[0]->{process_future} //= $_[0]->loop->new_future }

sub on_line {
	my ($self, $line) = @_;

	if($self->state eq 'header') {
		$self->on_header($line);
	} elsif($self->state eq 'body') {
		$self->on_body($line);
	} else {
		die "unknown state " . $self->state;
	}
}

sub on_header {
	my ($self, $line) = @_;

	for($line) {
		if(my ($k, $v) = /^([^:]+):\s+(.*)$/) {
			$self->{header}{$k} = $v;
			$self->bus->invoke_event(header => $k => $v);
		} elsif(!length) {
			$self->state('body');
		} else {
			die "Invalid";
		}
	}
}

sub on_body {
	my ($self, $line) = @_;

	my ($module, $version, $dist) = split ' ', $line;
	warn "Unusual parameters: $module $version $dist\n" unless defined $dist;
	$self->bus->invoke_event(module => $module, $version, $dist);
}

sub state {
	my ($self) = shift;
	if(@_) {
		$self->{state} = shift;
		return $self
	}
	return $self->{state} //= 'header';
}

sub _add_to_loop {
	my ($self, $loop) = @_;
	my %args;
	if($self->use_zcat) {
		$args{command} = [
			qw(zcat), $self->source,
		]
	} else {
		$args{command} = [
			qw(cat), $self->source,
		]
	}
	my $f = $self->process_future;
	$self->add_child(
		my $proc = IO::Async::Process->new(
			%args,
			stdout => {
				on_read => sub {
					my ( $stream, $buffref, $eof ) = @_;
					while( $$buffref =~ s/^(.*)\n// ) {
						$self->on_line($1);
					}
					$self->on_line($$buffref) if $eof && $$buffref;
					return 0;
				},
			},
			on_finish => sub {
				my ($process, $exit) = @_;
				warn "Failed: $exit" if $exit;
				# print "The process has finished\n";
				$f->done($exit);
			},
			on_exception => sub {
				warn "something bad: @_";
				$f->fail(@_);
			}
		)
	);
	$proc->stdout->configure(
		read_high_watermark => 16384,
		read_low_watermark  => 512,
		read_len => 256,
	)
}

1;

