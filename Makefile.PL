BEGIN {
    # Okay, so some people wanting to check out the latest and greatest
    # version from github is getting stuck not knowing what M::I modules
    # to install. So do the check here
    my @modules = qw(
        inc::Module::Install
        Module::Install::AuthorTests
        Module::Install::ReadmeFromPod
        Module::Install::TestTarget
        Module::Install::XSUtil
    );

    my @missing;
    foreach my $module (@modules) {
        eval "require $module";
        push @missing, $module if $@;
    }
    if (@missing) {
        print STDERR <<EOM;

**** Missing Developer Tools! ****

Whoa there, you don't have the required modules to run this Makefile.PL!
This probably means you cloned the repository from github (if you
encounter this from a tarball uploaded to CPAN, it's a bug, so please
report it).

If you are running from a cloned git repository, install the following
modules first:
EOM
        foreach my $module (@missing) {
            $module =~ s/^inc:://;
            print "    * $module\n";
        }
        print STDERR <<EOM;
and try again.

While you're at it, install these modules as they are needed to run
the tests:

    * Test::Exception (at least 0.29)
    * Test::Requires
    * Test::TCP

EOM
        exit 0;
    }
    Module::Install->import;
}


name 'ZeroMQ';

{ # M::I is silly about multiple authors:
    my $mainpm = 'lib/ZeroMQ.pm';
    name_from $mainpm;
    version_from $mainpm;
    perl_version_from $mainpm;
    license_from $mainpm;
    abstract_from $mainpm;
    readme_from $mainpm;
    author 'Daisuke Maki <daisuke@endeworks.jp>';
    author 'Steffen Mueller <smueller@cpan.org>';
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
cc_libs 'zmq';

default_test_target 
    env => {
        LC_ALL => 'C'
    }
;
author_tests 'xt';
WriteAll;

if ($Module::Install::AUTHOR) {
    do 'tools/genfiles.pl';
}