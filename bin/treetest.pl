#!/usr/bin/env perl
use strict;
use warnings;
use Tickit::DSL qw(:async);

use Log::Any qw($log);
use Log::Any::Adapter qw(Stderr);

use Variable::Disposition qw(retain_future);
use Pancake::Model;

my $model = Pancake::Model->new;
vbox {
	desktop {
		# Main index tree on the left
		tree {
		} data => [
			'Authors' => Tickit::Widget::Tree::AdapterTransformation->new(
				adapter => $model->author,
				item    => sub {
					my ($k, $author) = @_;
					[
						Distributions => Tickit::Widget::Tree::AdapterTransformation->new(
							adapter => $author->distribution,
							item    => sub {
								my ($k, $dist) = @_;
								[
									Releases      => Tickit::Widget::Tree::AdapterTransformation->new(
										adapter => $dist->release,
										item    => sub {
											my ($k, $release) = @_;
											[
												Files => [],
											]
										}
									)
								]
							}
						),
						Modules       => Tickit::Widget::Tree::AdapterTransformation->new(
							adapter => $author->module,
							item    => sub {
								my ($k, $module) = @_;
								[ ]
#									Documentation => [],
#									Exports => [],
#									Functions => [],
#								]
							}
						),
					]
				}
			)
		], 'parent:label'  => 'Authors',
		   'parent:top'    => 0,
		   'parent:left'   => 0,
		   'parent:cols'   => 30,
		   'parent:bottom' => 0;
		# Active tasks
#		logpanel stderr => 1,
#		   'parent:label'  => 'Current tasks',
#		   'parent:left'   => 29,
#		   'parent:right'  => 0,
#		   'parent:bottom' => 0,
#		   'parent:lines'  => 10;

	} 'parent:expand' => 1;
	statusbar {};
};
tickit->timer(
	after => 0.3,
	sub {
		use Pancake::Packages::Parser;
		loop->add(
			my $parser = Pancake::Packages::Parser->new(
				source => shift(@ARGV) // 't/data/02packages.sample.txt.gz',
			)
		);
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
			)->on_fail(sub { warn "failed? @_"; });
			$module{$module} ||= $model->add_module(
				path    => $dist,
				module  => $module,
				version => $version,
			)->on_fail(sub { warn "module failed? @_"; });
	#		++$module_count
		}
	);
	retain_future(
		$parser->process_future->then(sub {
			$log->debug("Done");
			use Data::Dumper;
			warn "Adapter for author is " . $model->author;
#			warn Dumper($model)
		})
	);
#		$model->author->set_key(
#			PEVANS => Pancake::Model::Author->new(
#				name => 'PEVANS',
#			)
#		);
	}
);
tickit->run;

