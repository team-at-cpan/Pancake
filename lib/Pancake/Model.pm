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
		my $release = Pancake::Model::Release->new(
			author => $author,
			distribution => $dist,
			version => $args{version},
		);
		$dist->release->set_key(
			$release->version => $release
		)->transform(
			done => sub { $release }
		)
	})
}

1;

