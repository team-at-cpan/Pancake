use strict;
use warnings;

use Test::More;

use Pancake::Packages::Parser;

use IO::Async::Loop;

my $loop = IO::Async::Loop->new;
$loop->add(
	my $parser = new_ok('Pancake::Packages::Parser', [
		source => 't/data/02packages.sample.txt',
	])
);

my %header;
$parser->bus->subscribe_to_event(
	header => sub {
		my ($ev, $k, $v) = @_;
		$header{$k} = $v
	}
);

my $module_count;
$parser->bus->subscribe_to_event(
	module => sub {
		my ($ev, $module, $dist, $version) = @_;
		++$module_count
	}
);

$parser->process_future->get;

{
	my %expected = (
		'File'         => '02packages.sample.txt',
		'URL'          => 'http://www.perl.com/CPAN/modules/02packages.details.txt',
		'Description'  => 'Some of the package names found in directory $CPAN/authors/id/',
		'Columns'      => 'package name, version, path',
		'Intended-For' => 'Automated fetch routines, namespace documentation.',
		'Written-By'   => 'A text editor',
		'Line-Count'   => 14,
		'Last-Updated' => 'Tue, 03 Feb 2015 11:53:19 GMT',
	);
	for my $k (sort keys %expected) {
		is($parser->header($k), $expected{$k}, "header $k matches");
		ok(exists $header{$k}, "received $k via header event");
		is($header{$k}, $parser->header($k), "received $k event matches current header");
	}
	is($parser->header('Line-Count'), $module_count, "line count matches module count");
}

done_testing;

