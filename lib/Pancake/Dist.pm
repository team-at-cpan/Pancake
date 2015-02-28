package Pancake::Dist;

use strict;
use warnings;

use CPAN::DistnameInfo;

sub new {
	my $class = shift;
	bless { @_ }, $class
}

sub new_from_distname {
	my ($class, $dist) = @_;
	my $info = CPAN::DistnameInfo->new($dist);
	$class->new(
		name      => $info->dist,
		version   => $info->version,
		filename  => $info->filename,
		extension => $info->extension,
		author    => $info->cpanid
	);
}

sub name { shift->{name} }
sub version { shift->{version} }
sub filename { shift->{filename} }
sub extension { shift->{extension} }
sub author { shift->{author} }

1;

