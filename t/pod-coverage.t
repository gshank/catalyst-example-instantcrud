#!perl -T

use Test::More;
if (!$ENV{AUTHOR_TEST}) {
    plan skip_all => 'Author test';
}
else{
    eval "use Test::Pod::Coverage 1.04";
    plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
}
all_pod_coverage_ok();

