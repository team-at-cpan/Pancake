package Pancake::Model::LocalLib;

use strict;
use warnings;

use Adapter::Async::Model {
	path => 'string',
	distribution => {
		collection => 'UnorderedMap',
		item       => '::Distribution',
		key        => 'string',
	},
	installing => {
		collection => 'UnorderedMap',
		item       => '::Installation',
		key        => 'string',
	},
};

1;

