use inc::Module::Install;

name 'Croque';
all_from 'lib/Croque.pm';

requires 'Exporter';
requires 'Proc::Simple';
requires 'Time::Piece';
requires 'Time::HiRes';
requires 'Guard';
test_requires 'Test::More';
test_requires 'File::Spec';
test_requires 'File::Slurp';

tests 't/*.t';

WriteAll;
