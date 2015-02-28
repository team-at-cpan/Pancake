package Pancake::Model::Distribution;

use strict;
use warnings;

use Pancake::Definition {
	release      => {
		collection => 'OrderedList',
		item       => '::Release',
	},
	issue        => {
		collection => 'UnorderedMap',
		item       => '::Issue',
		key        => 'string',
	},
	name         => 'string',
	path         => 'string',
};

1;
