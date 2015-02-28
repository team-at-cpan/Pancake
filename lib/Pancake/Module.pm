package Pancake::Module;

use strict;
use warnings;

use Pancake::Definition {
	module => 'string',
	version => 'string',
	dist => 'string',
};

use Future;
use Module::Metadata;

sub new {
	my $class = shift;
	bless { @_ }, $class
}

sub module { shift->{module} }

sub version { shift->{version} }

sub dist { shift->{dist} }

sub filename {
	my ($self) = @_;
	(my $file = $self->module) =~ s{::}{/}g;
	$file .= '.pm';
	$file
}

sub install_path {
	my ($self, @extra) = @_;
	my $file = $self->filename;
	my ($path) = grep -r, map { "$_/$file" } @extra, @INC;
	return Future->done($path) if defined $path;
	return Future->fail($self->module . " not installed", module => $self);
}

sub is_perl {
	my ($self) = @_;
	$self->dist =~ m{/perl-[0-9._-rc]+\.tar\.(gz|bz2)$}i ? 1 : 0;
}

sub current_version {
	my ($self) = @_;
	$self->install_path->then(sub {
		my $meta = Module::Metadata->new_from_file(shift);
		return Future->fail('could not extract our version info') unless defined($meta->version);

		Future->done(version->parse($meta->version));
	})
}

1;

