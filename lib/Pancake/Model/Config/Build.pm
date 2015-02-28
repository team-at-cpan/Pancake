package Pancake::Model::Config::Build;

use strict;
use warnings;

use Adapter::Async::Model {
	path              => 'string',
	preferred_builder => 'string',
	jobs              => 'int',
};

1;
