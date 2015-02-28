package Pancake::Model::Release;

use strict;
use warnings;

use Adapter::Async::Model {
	distribution => '::Distribution',
	author       => '::Author',
	version      => 'version',
	path         => 'string',
	license      => 'string',
	abstract     => 'string',
	status       => 'string',
	homepage     => 'string',
};

1;
