use strict;
use warnings;

use Tasks;

my $app = Tasks->apply_default_middlewares(Tasks->psgi_app);
$app;

