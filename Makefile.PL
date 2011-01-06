BEGIN {
    do 'tools/check_mi_mods.pl';
}


name 'ZeroMQ';

{ # M::I is silly about multiple authors:
    my $mainpm = 'lib/ZeroMQ.pm';
    name_from $mainpm;
    version_from $mainpm;
    perl_version_from $mainpm;
    license_from $mainpm;
    abstract_from $mainpm;
    author 'Daisuke Maki <daisuke@endeworks.jp>';
    author 'Steffen Mueller <smueller@cpan.org>';
    if ($Module::Install::AUTHOR) {
        readme_from $mainpm;
    }
}

test_requires 'Test::TCP';
test_requires 'Test::Requires';
test_requires 'Test::Exception' => '0.29';
recommends 'JSON' => '2.00';
use_xshelper '-clean';

use_ppport;
cc_warnings;
if ($ENV{INCLUDES}) {
    cc_include_paths split/\s+/, $ENV{INCLUDES};
}
if ($ENV{LIBS}) {
    cc_libs $ENV{LIBS};
}
cc_src_paths 'xs';
cc_assert_lib 'zmq';
cc_libs 'zmq', 'uuid'; # uuid for cygwin, but can't hurt

default_test_target 
    env => {
        LC_ALL => 'C'
    }
;
author_tests 'xt';

do 'tools/genfiles.pl';
WriteAll;