package Pancake::Module;

use strict;
use warnings;

sub new {
	my $class = shift;
	bless { @_ }, $class
}

1;

