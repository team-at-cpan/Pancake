package Pancake::Model::Config;

use strict;
use warnings;

use Adapter::Async::Model {
	build    => '::Config::Build',
	download => '::Config::Download',
	sqlite   => '::Config::SQLite',
};

1;
