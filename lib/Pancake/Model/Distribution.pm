package Pancake::Model::Distribution;

use strict;
use warnings;

use Adapter::Async::Model {
	release      => {
		collection => 'UnorderedMap',
		item       => '::Release',
	},
	issue        => {
		collection => 'UnorderedMap',
		item       => '::Issue',
		key        => 'string',
	},
	module       => {
		collection => 'UnorderedMap',
		item       => '::Module',
		key        => 'string',
	},
	name         => 'string',
	path         => 'string',
};

1;
