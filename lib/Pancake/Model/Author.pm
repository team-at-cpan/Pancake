package Pancake::Model::Author;

use strict;
use warnings;

use Adapter::Async::Model {
	name         => 'string',
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
};

1;
