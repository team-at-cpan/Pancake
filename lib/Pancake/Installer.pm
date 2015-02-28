package Pancake::Installer;

use strict;
use warnings;

use parent qw(IO::Async::Notifier);

use Data::Dumper;
use Log::Any qw($log);
use POSIX qw(strftime);

# Can't use it directly, since it will affect our @INC and
# default install paths. We'll import later after %ENV localisation
BEGIN { require local::lib; }
use Archive::Tar;
use File::Basename;
use File::Spec;
use File::Path qw(make_path rmtree);
use File::pushd qw(tempd pushd);
use File::Temp qw(tempdir);
use Variable::Disposition qw(retain_future);

use Net::Async::HTTP;
use IO::Async::Process;
use JSON::MaybeXS;

sub temp_path { '/tmp/pancake' }

sub json { shift->{json} ||= JSON::MaybeXS->new }

sub ua {
	my ($self) = @_;
	$self->{ua} ||= do {
		my $ua = Net::Async::HTTP->new(
			stall_timeout            => 30,
			user_agent               => 'Mozilla/4.0 (not very compatible; pancake; linux; Net-Async-HTTP/' . Net::Async::HTTP->VERSION . ')',
			decode_content           => 1,
			pipeline                 => 0,
			fail_on_error            => 1,
			max_in_flight            => 0,
			max_connections_per_host => 4,
		);
		$self->loop->add($ua);
		$ua
	}
}

sub download {
	my ($self, $release) = @_;
	my $loop = $self->loop;

	my $dist_file = $self->temp_path . '/dist/' . $release->path;
	$log->debugf("Distribution file will be in %s", $dist_file);
	make_path File::Basename::dirname($dist_file); 
	# or die "failed to create path for $dist_file";

	(-r $dist_file
		? Future->done($dist_file)
		: $self->ua->GET(
			"http://cpan.perlsite.co.uk/authors/id/" . $release->path,
			on_header => sub {
				my ($hdr) = @_;
				my $f = $loop->new_future;
				open my $fh, '>', $dist_file or die "unable to open $dist_file for write - $!";
				binmode $fh;
				sub {
					if(@_) {
						my ($data) = @_;
						$fh->print($data) or die $!;
					} else {
						$f->done;
						$fh->close or die $!;
						return $hdr;
					}
				}
			}
		)->on_fail(sub { warn "HTTP failure - @_" })
		 ->transform(
			 done => sub { $dist_file }
		 )
	)
}

sub extract {
	my ($self, $release, $dist_file, $target) = @_;
	$log->debugf("Opening TAR for %s", $dist_file);
	my $count = 0;
	{ # Iterate through everything in this file
		my $temp = pushd $target;
		my $tar = Archive::Tar->iter(
			$dist_file, 1, { }
		);
		while(my $f = $tar->()) {
			$log->tracef("Filename %s (%s)", $f->name, $f->full_path);
			$f->extract;
			++$count;
		}
	}

	$log->debugf("Extracted %d files for %s", $count, $dist_file);
	Future->done(
		$target
	)
}

sub find_buildfile {
	my ($self, $release, $dir) = @_;
	$log->debugf("Locating build file in %s", $dir);
	my @pending = $dir;
	my $build;
	my %build_scripts = (
		'Makefile.PL' => 1,
		'Build.PL'    => 1,
	);
	while(@pending) {
		my $item = shift @pending;
		$log->tracef("Have item %s",$item);
		if(-d $item) {
			push @pending, glob "$item/*"
		} else {
			if(grep exists $build_scripts{$_}, File::Basename::basename($item)) {
				$log->debugf("Found build %s", $item);
				$build = $item;
				last
			}
		}
	}
	return defined($build)
		? Future->done($build)
		: Future->fail("No build file found")
}

sub install {
	my ($self, $release) = @_;
	my $loop = $self->loop;

	my $dir = tempdir();
	$log->debugf("Temp directory will be %s", $dir);

	my $install = Pancake::Model::Installation->new(
		release => $release,
		path    => $dir,
		target  => $self->local_lib_base,
	);
	my $output = sub {
		my ($type, $str) = @_;
		my $method = "${type}_output";
		$log->tracef("%s %s [%s] %s", $release->distribution->name, $release->version, $type, $str);
		$install->$method->push([ $str ])
	};
	my %test;
	my %record = (
		start => sub {
			my ($file, $time) = split /:/, shift;
			retain_future($install->test->set_key(
				$file => $test{$file} = Pancake::Model::Test->new(
					install => $install,
					file    => $file,
					start   => $time,
					passed  => 0,
					failed  => 0,
					skipped => 0,
					count   => 0,
					status  => 'running',
				)
			))
		},
		close => sub {
			my ($file, $time) = split /:/, shift;
			$test{$file}
				->elapsed($time - $test{$file}->start)
				->status('finished');
		},
		TAP => sub {
			my ($file, $elapsed, $raw) = split /:/, shift, 3;
			my $tap = Pancake::Model::TAP->new(
				test => $test{$file},
				time => $elapsed,
			);
			$tap->apply_line($raw);
			$test{$file}->output->push([ $tap ]);
		},
	);
	$self->download(
		$release
	)->then(sub {
		my ($dist_file) = @_;
		$self->extract(
			$release, $dist_file, $dir
		)->then(sub {
			$self->find_buildfile(
				$release, $dir
			)
		})->then(sub {
			my ($build) = @_;
			eval {
				my $f = $loop->new_future;
				$log->debugf("Directory should be %s for %s", File::Basename::dirname($build), $build);
				make_path '/tmp/pancake/install-test';
				my $chdir = File::Basename::dirname($build);
				my $build_script = File::Basename::basename($build);
				my $type = $build_script eq 'Build.PL' ? 'Module::Build' : 'ExtUtils::MakeMaker';
				$self->spawn(
					command => [
						$^X, File::Basename::basename($build),
						# manpages? meh. ideally this would be a config option, but
						# I don't care enough yet to bother, raise an RT if you want
						# to be able to disable this
						$type eq 'Module::Build'
						? (qw(--install_path libdoc= --install_path bindoc=))
						: (qw(INSTALLMAN1DIR=none INSTALLMAN3DIR=none))
					],
					chdir => $chdir,
					stdout => sub { $output->(configure => shift) },
					stderr => sub { $output->(configure => shift) },
				)->then(sub {
					warn "After process\n";
					my $meta = do {
						my $dir = pushd(File::Basename::dirname($build));
						open my $fh, '<:encoding(UTF-8)', 'MYMETA.json' or die "No mymeta.json? $!";
						$self->json->decode(join '', <$fh>);
					};
					# $module{$module}{meta} = $meta;
					warn "Directory: $dir\n";
					# might want to be careful with this one
					Future->done
				})->then(sub {
					$self->spawn(
						command => (
							$type eq 'Module::Build'
							? [ $^X, 'Build' ]
							: [ qw(make) ]
						),
						chdir => $chdir,
						stdout => sub { $output->(build => shift) },
						stderr => sub { $output->(build => shift) },
					)
				})->then(sub {
					$self->spawn(
						command => (
							$type eq 'Module::Build'
							? [ $^X, qw(Build test) ]
							: [ qw(make test) ]
						),
						chdir => $chdir,
						stdout => sub { $output->(test => shift) },
						stderr => sub { $output->(test => shift) },
						fd3 => {
							via => 'pipe_read',
							on_read => sub {
								my ($stream, $buf, $eof) = @_;
								while($$buf =~ s/^(.*)\n//) {
									my ($type, $detail) = split /:/, $1, 2;
									$record{$type}->($detail);
								}
								0
							}
						}
					)
				})->then(sub {
					$self->spawn(
						command => (
							$type eq 'Module::Build'
							? [ $^X, qw(Build install) ]
							: [ qw(make install) ]
						),
						chdir => $chdir,
						stdout => sub { $output->(install => shift) },
						stderr => sub { $output->(install => shift) },
					)
				})->then(sub {
					$log->debugf("Done build for %s", $dist_file);
					for my $k (sort keys %test) {
						$log->debugf("Test [%s] status %s - %d passed, %d failed, %d skipped of %d total (%s)", $k, $test{$k}->status, $test{$k}->passed, $test{$k}->failed, $test{$k}->skipped, $test{$k}->count, strftime '%H:%M:%S', gmtime $test{$k}->elapsed);
					}
					rmtree $dir if $dir =~ m{^/tmp/} && $dir !~ m{\.};
#					warn Dumper($install);
					Future->wrap; # ($meta)
				})
			} or do { warn "failure - $@ on $dist_file"; die $@ }
		})
	})->on_fail(sub { warn "Failure: @_" });
}

sub spawn {
	my ($self, %args) = @_;

	local %ENV = %ENV;
	local @INC = @INC;
	local::lib->import($self->local_lib_base);
	# FIXME haxx
	$ENV{PERL5LIB} = '/home/tom/dev/gitperl/Pancake/lib:' . $ENV{PERL5LIB};
	$ENV{HARNESS_SUBCLASS} = 'Pancake::TAP::Harness';

	my $chdir = delete $args{chdir} || $self->local_lib_base;
	my $setup = delete $args{setup} || [];
	my $stdout = delete $args{stdout} || sub {
		$log->warnf("unhandled stdout - %s", shift)
	};
	my $stderr = delete $args{stderr} || sub {
		$log->warnf("unhandled stderr - %s", shift)
	};

	my $f = $self->loop->new_future;
	$self->add_child(
		my $process = IO::Async::Process->new(
			setup => [
				chdir => $chdir,
				@$setup,
			],
			stdout => {
				on_read => sub {
					my ( $stream, $buffref ) = @_;
					while( $$buffref =~ s/^(.*)\n// ) {
						$stdout->($1);
					}
					return 0;
				},
			},
			stderr => {
				on_read => sub {
					my ( $stream, $buffref ) = @_;
					while( $$buffref =~ s/^(.*)\n// ) {
						$stderr->($1);
					}
					return 0;
				},
			},
			on_finish => sub {
				my ($process, $exit) = @_;
				$log->warnf("Failed - %s", $exit) if $exit;
				$log->info("Process finished");
				$f->done($exit);
			},
			on_exception => sub {
				$log->errorf("Had exception %s", join ' ', @_);
				$f->fail(@_);
			},
			%args
		)
	);
	retain_future($f)
}

sub local_lib_base { qw(/tmp/pancake/install-test) }

sub configure {
	my ($self, %args) = @_;
	for(grep exists $args{$_}, qw(model)) {
		$self->{$_} = delete $args{$_}
	}
	$self->SUPER::configure(%args)
}
1;

