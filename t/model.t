use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Variable::Disposition;

use Pancake::Model;
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

can_ok('Pancake::Model::Distribution', qw(name release));
can_ok('Pancake::Model::Author',       qw(name));
can_ok('Pancake::Model::Issue',        qw(subject status));
can_ok('Pancake::Model::Release',      qw(author distribution));

{
	my $dist = new_ok('Pancake::Model::Distribution', [
	]);
	my $release;
	{
		done_future($dist->release->set_key(
			'0.001' => $release = new_ok('Pancake::Model::Release', [
			])
		), 'can push release immediately');

		is_ref($dist->release->get_key('0.001')->get, $release, 'pushed the right instance');
		Scalar::Util::weaken($release);
		ok($release, 'weakref for release is still valid');
	}
	is(exception { dispose $dist }, undef, 'can dispose dist');
	ok(!$release, 'release went away as well');
}

{
	my $model = new_ok('Pancake::Model');
	ok(!$model->author->exists('TEAM')->get, 'no author yet');
	ok(!$model->author->exists('TEAM')->get, 'still no author yet');
	ok(!$model->distribution->exists('Pancake')->get, 'no dist yet');
	my $release;
	is(exception {
		$release = $model->add_release(
			path => 'T/TE/TEAM/Pancake-0.001.tar.gz',
		)->get
	}, undef, 'can add a release via the model');
	ok($release, 'release seems to be a thing');
	ok($model->author->exists('TEAM')->get, 'now have the author');
	ok($model->distribution->exists('Pancake')->get, 'and the dist');
	ok(my $author = $model->author->get_key('TEAM')->get, 'have the author');
	ok(my $dist = $model->distribution->get_key('Pancake')->get, 'and the dist');
	isa_ok($author, 'Pancake::Model::Author');
	is($author->name, 'TEAM', 'author name was correct');
	isa_ok($dist, 'Pancake::Model::Distribution');
	is($dist->name, 'Pancake', 'dist name was correct');
	isa_ok($release, 'Pancake::Model::Release');
	is_ref($release->distribution, $dist, 'release distribution is correct');
	is_ref($release->author, $author, 'release author is correct');
	is_ref($dist->release->get_key($release->version)->get, $release, 'release is in distribution list');
}

done_testing;

