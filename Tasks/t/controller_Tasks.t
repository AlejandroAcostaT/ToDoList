use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Tasks';
use Tasks::Controller::Tasks;

ok( request('/tasks')->is_success, 'Request should succeed' );
done_testing();