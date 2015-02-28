package Pancake::App;
use strict;
use warnings;

use Log::Any qw($log);
use IO::Async::Loop;

use Pancake::Packages::Parser;
use Pancake::Author;
use Pancake::Dist;

sub new { my $class = shift; bless { @_ }, $class }

sub run {
	my ($self, @argv) = @_;
	$self->{loop} = my $loop = IO::Async::Loop->new;
	$self->import_module_list->get;
}

sub loop { shift->{loop} }

sub package_parser {
	my ($self) = @_;
	$self->{package_parser} ||= do {
		$self->loop->add(
			my $parser = Pancake::Packages::Parser->new(
				source => 't/data/02packages.sample.txt',
			)
		);
		$parser
	}
}

sub import_module_list {
	my ($self) = @_;
	my $parser = $self->package_parser;
	my %header;
	$parser->bus->subscribe_to_event(
		header => sub {
			my ($ev, $k, $v) = @_;
			$header{$k} = $v;
			warn "Header [$k] => $v\n";
		}
	);

	my %author;
	my %dist;
	my %module;
	my $module_count;
	$parser->bus->subscribe_to_event(
		module => sub {
			my ($ev, $module, $version, $dist) = @_;
			$module{$module} = {
				dist    => $dist,
				version => $version
			};
			unless(exists $dist{$dist}) {
				$log->debugf("Have new dist %s", $dist);
				$dist{$dist} = Pancake::Dist->new_from_distname($dist);
			}
			my $d = Pancake::Dist->new_from_distname($dist);
			$log->debugf("Dist %s, module %s, author %s", $dist, $module, $dist{$dist}->author);
			unless(exists $author{$dist{$dist}->author}) {
				$log->debugf("Have new author %s", $d->author);
				$author{$d->author} = Pancake::Author->new(
					name => $d->author
				);
			}
			++$module_count
		}
	);
	$parser->process_future->on_done(sub {
		warn "Total module count: $module_count\n";
	})
}

1;

