package Pancake::Model;

use strict;
use warnings;

use Pancake::Definition {
	author       => {
		collection => 'UnorderedMap',
		item       => '::Author',
		key        => 'string',
	},
	distribution => {
		collection => 'UnorderedMap',
		item       => '::Distribution',
		key        => 'string',
	},
};

use CPAN::DistnameInfo;

sub add_release {
	my ($self, %args) = @_;
	if($args{path}) {
		my $info = CPAN::DistnameInfo->new($args{path});
		$args{version} //= $info->version;
		$args{distribution} //= $info->dist;
		$args{filename} //= $info->filename;
		$args{extension} //= $info->extension;
		$args{author} //= $info->cpanid;
	}

	Future->needs_all(
		$self->get_or_create(author => $args{author}, sub {
			Pancake::Model::Author->new(
				name => $args{author}
			)
		}),
		$self->get_or_create(distribution => $args{distribution}, sub {
			Pancake::Model::Distribution->new(
				name => $args{distribution}
			)
		}),
	)->then(sub {
		my ($author, $dist) = @_;
		Future->done(
			Pancake::Model::Release->new(
				author => $author,
				distribution => $dist,
			)
		)
	})
}

sub get_or_create {
	my ($self, $type, $v, $create) = @_;
	return Future->done($v) if ref $v;
	$self->$type->exists($v)->then(sub {
		return $self->$type->get_key($v) if shift;

		my $item = $create->($v);
		$self->$type->set_key(
			$v => $item
		)->transform(
			done => sub { $item }
		)
	})
}

1;

