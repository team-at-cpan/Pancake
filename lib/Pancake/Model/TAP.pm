package Pancake::Model::TAP;

use strict;
use warnings;

use Pancake::Definition {
	test         => '::Test',
	raw          => 'string',
	index        => 'int',
	depth        => 'int',
	time         => 'time',
	type         => 'string',
	detail       => 'string',
};

use Log::Any qw($log);

sub apply_line {
	my ($self, $line) = @_;
	chomp($line);
	$self->raw($line);
	my $depth = 0;
	++$depth while $line =~ s/^    //;
	$self->depth($depth);
	if($depth && $line =~ /^# Subtest: (.*)$/) {
		$self->detail($1);
		$self->type('subtest');
	} elsif($line =~ /^#\s?(.*)$/) {
		$self->detail($1);
		$self->type('comment');
	} elsif($line =~ /^1\.\.(\d+)$/) {
		my $count = $1;
		$self->detail($count);
		$self->type('plan');
		$self->test->count($self->test->count + $count);
	} elsif($line =~ /^ok (\d+)(?:(?: -)?\s?(.*))?$/) {
		$self->index($1);
		$self->detail($2);
		$self->type('pass');
		$self->test->passed($self->test->passed + 1);
	} elsif($line =~ /^(?:not )?ok (\d+) # skip (.*)?$/) {
		$self->index($1);
		$self->detail($2);
		$self->type('skip');
		$self->test->skipped($self->test->skipped + 1);
	} elsif($line =~ /^not ok (\d+)(?:(?: -)?\s?(.*))?$/) {
		$self->index($1);
		$self->detail($2);
		$self->type('fail');
		$self->test->failed($self->test->failed + 1);
	} elsif($line =~ /^1\.\.0 # SKIP (.*)$/) {
		$self->detail($1);
		$self->type('skip');
	} else {
		$log->warnf("Unknown TAP line [%s]", $line);
	}
	$self
}

1;
