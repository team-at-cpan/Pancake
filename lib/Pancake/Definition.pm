package Pancake::Definition;

use strict;
use warnings;

use Log::Any qw($log);

use Future;

use Module::Load;
use Data::Dumper;

sub import {
	my ($class, $def, %args) = @_;

	my %loader;
	my $pkg = caller;
	for my $k (keys %$def) {
		my $details = $def->{$k};
		$details = { type => $details } unless ref $details;
		my $code;
		my %collection_class_for = (
			UnorderedMap => 'Adapter::Async::UnorderedMap::Hash',
			OrderedList  => 'Adapter::Async::OrderedList::Array',
		);

		if(my $type = $details->{collection}) {
			my $collection_class = $collection_class_for{$type} // die "unknown collection $type";
			++$loader{$collection_class};
			$log->tracef("%s->%s collection: %s", $pkg, $k, $type);
			++$loader{$_} for grep /::/, map $class->type_expand($_), @{$details}{qw(key item)};
			$code = sub {
				my $self = shift;
				die "no args expected" if @_;
				$self->{$k} //= $collection_class->new;
			}
		} else {
			my $type = $class->type_expand($details->{type} // die "unknown type in package $pkg - " . Dumper($def));
			++$loader{$type} if $type =~ /::/;

			$log->tracef("%s->%s scalar %s", $pkg, $k, $type);
			$code = sub {
				my ($self) = shift;
				return $self->{$k} unless @_;
				$self->{$k} = shift;
				return $self
			}
		}

		{ # Apply the method
			no strict 'refs';
			*{$pkg . '::' . $k} = $code;
			*{$pkg . '::new'} = sub {
				my ($class) = shift; bless { @_ }, $class
			};
			*{$pkg . '::get_or_create'} = sub {
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
			};
		}
	}

	for(sort keys %loader) {
		$log->tracef("Loading %s for %s", $_, $pkg);
		Module::Load::load($_) 
	}
}

sub type_expand {
	my ($class, $type) = @_;
	return unless defined $type;
	$type = 'Pancake::Model' . $type if substr($type, 0, 2) eq '::';
	$type
}

1;

