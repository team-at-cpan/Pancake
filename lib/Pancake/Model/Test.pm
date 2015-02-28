package Pancake::Model::Test;

use strict;
use warnings;

use Adapter::Async::Model {
	installation => '::Installation',
	file         => 'string',
	start        => 'time',
	elapsed      => 'time',
	status       => 'string',
	count        => 'int',
	passed       => 'int',
	failed       => 'int',
	skipped      => 'int',
	output       => {
		collection => 'OrderedList',
		item       => '::TAP',
	},
};

1;
