package Pancake::Hub;

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
};

1;

