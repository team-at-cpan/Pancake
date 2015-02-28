use strict;
use warnings;

use Test::More;

use Pancake::Module;

{
	my $module = new_ok('Pancake::Module', [
		module => 'Some::Module',
	]);
	is($module->module, 'Some::Module', 'module name matches');
	is($module->filename, 'Some/Module.pm', 'filename looks about right');
	my ($path) = $module->install_path('t/lib')->get;
	ok($path, 'can find install path');
	is($path, 't/lib/Some/Module.pm', 'install path matches our expectations');
}

done_testing;

