package Pancake::Author;

use strict;
use warnings;

sub new {
	my $class = shift;
	bless { @_ }, $class
}

sub name { shift->{name} }

1;

