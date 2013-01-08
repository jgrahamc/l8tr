package L8tr;

$L8tr::root    = '/home/jgc/';
$L8tr::add     = '/tmp/l8tr.add';
$L8tr::storage = $root . 'l8tr.storage';
$L8tr::process = $root . 'l8tr.processing';

$L8tr::STATE_NONE      = 0;
$L8tr::STATE_OK        = 1;
$L8tr::STATE_SMALL     = 2;
$L8tr::STATE_HASH      = 3;
$L8tr::STATE_SPAM      = 4;
$L8tr::STATE_KILL      = 5;
$L8tr::STATE_DELIVERED = 6;

@L8tr::states = ( 'pending', 'deliver', 'review', 'hash', 'spam', 'delete',
                     'delivered' );

$L8tr::start_interval = 7.5 * 60;
$L8tr::max_interval = 6 * 60 * 60;
