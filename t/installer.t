use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Variable::Disposition;

use Log::Any::Adapter qw(Stdout);

use Pancake::Model;
use Pancake::Installer;
use Scalar::Util qw(refaddr);

sub done_future($;$) {
	my ($f, $msg) = @_;
	fail("$msg - future not ready") unless $f->is_ready;
	ok($f->is_done, $msg);
}

sub is_ref($$;$) {
	my ($actual, $expected, $msg) = @_;
	is(refaddr($actual), refaddr($expected), $msg);
}

{
	use IO::Async::Loop;
	my $loop = IO::Async::Loop->new;
	my $model = new_ok('Pancake::Model');
	$loop->add(
		my $installer = new_ok('Pancake::Installer', [
			model => $model
		])
	);
	my $release;
	is(exception {
		$release = $model->add_release(
			path => 'T/TE/TEAM/Adapter-Async-0.011.tar.gz',
		)->get
	}, undef, 'can add a release via the model');
	ok($release, 'release seems to be a thing');
	is(exception {
		$installer->install($release)->get;
	}, undef, 'can install');

	is(exception {
		$release = $model->add_release(
			path => 'P/PE/PEVANS/Test-Refcount-0.08.tar.gz',
		)->get
	}, undef, 'can add a release via the model');
	ok($release, 'release seems to be a thing');
	is(exception {
		$installer->install($release)->get;
	}, undef, 'can install');
}

done_testing;

