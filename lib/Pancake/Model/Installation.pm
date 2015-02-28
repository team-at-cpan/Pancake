package Pancake::Model::Installation;

use strict;
use warnings;

use Adapter::Async::Model {
	release      => '::Release',
	path         => 'string',
	start        => 'time',
	configure_output => {
		collection => 'OrderedList',
		item       => 'string',
	},
	build_output     => {
		collection => 'OrderedList',
		item       => 'string',
	},
	test_output      => {
		collection => 'OrderedList',
		item       => 'string',
	},
	install_output   => {
		collection => 'OrderedList',
		item       => 'string',
	},
	test         => {
		collection => 'UnorderedMap',
		key        => 'string',
		item       => '::Test',
	}
};

1;
