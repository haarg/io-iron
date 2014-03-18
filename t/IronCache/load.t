#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

require IO::Iron::IronCache::Client;
require IO::Iron::IronCache::Cache;
require IO::Iron::IronCache::Item;

plan tests => 21;

BEGIN {
	use_ok('IO::Iron::IronCache::Client') || print "Bail out!\n";
	can_ok('IO::Iron::IronCache::Client', 'new');
	can_ok('IO::Iron::IronCache::Client', 'get_caches');
	can_ok('IO::Iron::IronCache::Client', 'create_cache');
	can_ok('IO::Iron::IronCache::Client', 'get_cache');
	can_ok('IO::Iron::IronCache::Client', 'delete_cache');
	can_ok('IO::Iron::IronCache::Client', 'get_info_about_cache');

	use_ok('IO::Iron::IronCache::Cache') || print "Bail out!\n";
	can_ok('IO::Iron::IronCache::Cache', 'new');
	can_ok('IO::Iron::IronCache::Cache', 'put');
	can_ok('IO::Iron::IronCache::Cache', 'increment');
	can_ok('IO::Iron::IronCache::Cache', 'get');
	can_ok('IO::Iron::IronCache::Cache', 'delete');
	# Attributes
	can_ok('IO::Iron::IronCache::Cache', 'name');

	use_ok('IO::Iron::IronCache::Item') || print "Bail out!\n";
	can_ok('IO::Iron::IronCache::Item', 'new');
	# Attributes
	can_ok('IO::Iron::IronCache::Item', 'value');
	can_ok('IO::Iron::IronCache::Item', 'expires_in');
	can_ok('IO::Iron::IronCache::Item', 'replace');
	can_ok('IO::Iron::IronCache::Item', 'add');
	can_ok('IO::Iron::IronCache::Item', 'cas');
}

#use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.

diag("Testing IO::Iron::IronCache $IO::Iron::IronCache::Client::VERSION, Perl $], $^X");

#if(! -e File::Spec->catfile(File::HomeDir->my_home, '.iron.json') 
#		&& ! defined $ENV{'IRON_PROJECT_ID'}
#		&& ! -e File::Spec->catfile(File::Spec->curdir(), 'iron.json')) {
#	BAIL_OUT("NO IRONMQ CONFIGURATION FILE OR ENV VARIABLE IN PLACE! CANNOT CONTINUE!");
#}
