requires 'parent', 0;
requires 'curry', 0;
requires 'Future', '>= 0.30';
requires 'Mixin::Event::Dispatch', '>= 1.006';
requires 'Tickit::DSL', '>= 0.025';
requires 'Heap', '>= 0.63';
requires 'IO::Async', '>= 0.63';
requires 'Net::Async::HTTP', '>= 0.37';
requires 'Net::Async::Memcached', '>= 0.001';
requires 'Net::Async::Statsd', '>= 0.004';
requires 'Process::Async', '>= 0.001';
requires 'Cache::LRU', 0;
requires 'local::lib', '>= 2.000';
requires 'Tangence', '>= 0.20';
requires 'Net::Async::Tangence', '>= 0.12';
requires 'Variable::Disposition', '>= 0.002';

on 'test' => sub {
	requires 'Test::More', '>= 0.98';
	requires 'Test::Fatal', '>= 0.010';
	requires 'Test::Refcount', '>= 0.07';
};

