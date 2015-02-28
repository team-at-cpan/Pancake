#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(say);

use Pancake::Packages::Parser;
use Pancake::Model;

#use Log::Any::Adapter qw(Stdout);

use IO::Async::Loop;

my $loop = IO::Async::Loop->new;
$loop->add(
	my $parser = Pancake::Packages::Parser->new(
		source => shift(@ARGV) // 't/data/02packages.sample.txt',
	)
);

my %header;
$parser->bus->subscribe_to_event(
	header => sub {
		my ($ev, $k, $v) = @_;
		$header{$k} = $v
	}
);

my $model = Pancake::Model->new;
my %dist;
my %module;
$parser->bus->subscribe_to_event(
	module => sub {
		my ($ev, $module, $version, $dist) = @_;
#		$module{$module} = {
#			dist => $dist,
#			version => $version
#		};
		$dist{$dist} ||= $model->add_release(
			path => $dist
		);
		$module{$module} ||= $model->add_module(
			path    => $dist,
			module  => $module,
			version => $version,
		);
#		++$module_count
	}
);

$parser->process_future->get;
say "Finished loading packages";
Future->wait_all(
	values(%module),
	values(%dist)
)->get;
say "Finished populating model";
$model->module->each(sub {
	my ($k, $v) = @_;
	say "* $k (version " . $v->version . ")"
})->get;

