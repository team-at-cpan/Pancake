package Pancake::Model;

use strict;
use warnings;

use Adapter::Async::Model {
	author       => {
		collection => 'UnorderedMap',
		item       => '::Author',
		key        => 'string',
	},
	distribution => {
		collection => 'UnorderedMap',
		item       => '::Distribution',
		key        => 'string',
	},
	module => {
		collection => 'UnorderedMap',
		item       => '::Module',
		key        => 'string',
	},
	installing => {
		collection => 'UnorderedMap',
		item       => '::Installation',
		key        => 'string',
	},
	installed => {
		collection => 'UnorderedMap',
		item       => '::Installation',
		key        => 'string',
	},
	failed => {
		collection => 'UnorderedMap',
		item       => '::Installation',
		key        => 'string',
	},
	local_lib      => {
		collection => 'OrderedList',
		item       => '::LocalLib',
	},
};

use Log::Any qw($log);
use Variable::Disposition qw(retain_future);
use CPAN::DistnameInfo;

sub add_release {
	my ($self, %args) = @_;
	if($args{path}) {
		my $info = CPAN::DistnameInfo->new($args{path});
		$args{version}      //= $info->version;
		$args{distribution} //= $info->dist;
		$args{filename}     //= $info->filename;
		$args{extension}    //= $info->extension;
		$args{author}       //= $info->cpanid;
	}
	return Future->fail('invalid version', model => 'invalid version supplied', \%args) unless defined $args{version};

	retain_future(
		eval {
			$log->debugf("Adding distribution %s version %s", $args{distribution}, $args{version});
			$self->author_and_dist(
				%args
			)->then(sub {
				my ($author, $dist) = @_;
				my $release = Pancake::Model::Release->new(
					author       => $author,
					distribution => $dist,
					version      => $args{version},
					path         => $args{path},
				);
				$dist->release->set_key(
					$release->version => $release
				)->transform(
					done => sub { $release }
				)
			})
		} or Future->fail($@, model => "unable to add release", \%args)
	)
}

sub author_and_dist {
	my ($self, %args) = @_;
	die "No author" unless defined($args{author});
	die "No distribution" unless defined($args{distribution});
	$self->get_or_create(author => $args{author}, sub {
		Pancake::Model::Author->new(
			name => $args{author}
		)
	})->then(sub {
		my ($author) = @_;
		Future->needs_all(
			$self->get_or_create(distribution => $args{distribution}, sub {
				Pancake::Model::Distribution->new(
					name => $args{distribution}
				);
			}),
			$author->distribution->exists($args{distribution})
		)->then(sub {
			my ($dist, $exists) = @_;
			return Future->done($author, $dist) if $exists;
			$author->distribution->set_key(
				$args{distribution} => $dist
			)->transform(
				done => sub { $author, $dist }
			)
		})
	})
}

sub add_module {
	my ($self, %args) = @_;
	retain_future(
		eval {
			die "No module provided" unless defined($args{module});

			if($args{path}) {
				my $info = CPAN::DistnameInfo->new($args{path});
				$args{version} //= $info->version;
				$args{distribution} //= $info->dist;
				$args{filename} //= $info->filename;
				$args{extension} //= $info->extension;
				$args{author} //= $info->cpanid;
			}
			die "No dist provided" unless defined($args{distribution});
			$log->debugf("Adding module %s", $args{module});
			$self->author_and_dist(
				%args
			)->then(sub {
				my ($author, $dist) = @_;
				eval {
					my $module = Pancake::Model::Module->new(
						name         => $args{module},
						author       => $author,
						distribution => $dist,
						version      => $args{version},
					);
#					$log->debug("Set key on " . $module->name . " to " . $module . " via " . $self->module);
					Future->needs_all(
						$author->module->set_key(
							$module->name => $module
						),
						$self->module->set_key(
							$module->name => $module
						),
						$dist->module->set_key(
							$module->name => $module
						)
					)->transform(
						done => sub { $module }
					)
				} or do {
					$log->errorf($@);
					Future->fail($@)
				}
			})
		} or Future->fail($@, model => 'unable to add module', \%args)
	)
}

1;

