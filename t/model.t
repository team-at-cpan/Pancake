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

can_ok('Pancake::Model::Distribution', qw(name release));
can_ok('Pancake::Model::Author',       qw(name));
can_ok('Pancake::Model::Issue',        qw(subject status));
can_ok('Pancake::Model::Release',      qw(author distribution));

{
	my $dist = new_ok('Pancake::Model::Distribution', [
	]);
	my $release;
	{
		done_future($dist->release->push([
			$release = new_ok('Pancake::Model::Release', [
			])
		]), 'can push release immediately');

		is(refaddr($dist->release->get(items => [0])->get->[0]), refaddr $release, 'pushed the right instance');
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
	is(exception {
		$model->add_release(
			path => 'T/TE/TEAM/Pancake-0.001.tar.gz',
		)->get
	}, undef, 'can add a release via the model');
	ok($model->author->exists('TEAM')->get, 'now have the author');
	ok($model->distribution->exists('Pancake')->get, 'and the dist');
	ok(my $author = $model->author->get_key('TEAM')->get, 'have the author');
	ok(my $dist = $model->distribution->get_key('Pancake')->get, 'and the dist');
	is($author->name, 'TEAM', 'author name was correct');
	is($dist->name, 'Pancake', 'dist name was correct');
}

done_testing;

