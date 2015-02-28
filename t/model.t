use strict;
use warnings;

use Test::More;

use Pancake::Model;

sub done_future($;$) {
	my ($f, $msg) = @_;
	fail("$msg - future not ready") unless $f->is_ready;
	ok($f->is_done, $msg);
}

can_ok('Pancake::Model::Distribution', qw(name release));
can_ok('Pancake::Model::Author',       qw(name));
can_ok('Pancake::Model::Issue',        qw(subject status));
can_ok('Pancake::Model::Release',      qw(author distribution));

my $dist = new_ok('Pancake::Model::Distribution', []);
done_future($dist->release->push([
	my $release = new_ok('Pancake::Model::Release', [])
]), 'can push release immediately');

done_testing;

