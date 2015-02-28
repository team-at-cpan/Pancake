package Pancake::Model::Module;

use strict;
use warnings;

use Adapter::Async::Model {
	distribution => '::Distribution',
	author       => '::Author',
	version      => 'version',
	name         => 'string',
};

1;
