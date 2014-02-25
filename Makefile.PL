use 5.008_004;
use inc::Module::Install 0.91;
use strict;
use warnings FATAL => 'all';
 
perl_version '5.008_004';
all_from 'lib/DBIx/Class/TopoSort.pm';
requires 'DBIx::Class';
requires 'Graph';
 
test_requires 'Test::Exception'   => '0.21';
test_requires 'Test::DBIx::Class' => '0.01';
test_requires 'Test::More'        => '0.88'; # done_testing
test_requires 'Test::Deep'        => '0.01';
test_requires 'List::MoreUtils'   => '0.01'; # first_index
 
WriteAll;
