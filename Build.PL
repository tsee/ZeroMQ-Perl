use 5.008;
use strict;
use warnings;
use Module::Build::WithXSpp;
use ExtUtils::Constant 'WriteConstants';
use File::Spec;

mkdir("buildtmp");
WriteConstants( # NOTE: keep this in sync with lib/ZeroMQ.pm
  NAME => 'ZeroMQ',
  C_FILE  => File::Spec->catfile("buildtmp", "const-c.inc"),
  XS_FILE => File::Spec->catfile("buildtmp", "const-xs.inc"),
  NAMES => [
# socket types
  qw(
    ZMQ_REQ ZMQ_REP

    ZMQ_PUB ZMQ_SUB

    ZMQ_DOWNSTREAM ZMQ_UPSTREAM

    ZMQ_PAIR
  ),
# socket recv flags
  qw(
    ZMQ_NOBLOCK
  ),
# get/setsockopt options
  qw(
    ZMQ_RCVMORE
    ZMQ_HWM
    ZMQ_SWAP
    ZMQ_AFFINITY
    ZMQ_IDENTITY
    ZMQ_RATE
    ZMQ_RECOVERY_IVL
    ZMQ_MCAST_LOOP
    ZMQ_SNDBUF
    ZMQ_RCVBUF

    ZMQ_SUBSCRIBE
    ZMQ_UNSUBSCRIBE
  ),
  ],
);

my $build = Module::Build::WithXSpp->new(
  module_name            => 'ZeroMQ',
  license                => 'perl',
  requires               => {
    'ExtUtils::XSpp'                  => '0.12',
    'ExtUtils::XSpp::Plugin::Cloning' => '0.01',
    'Storable'                        => '0',
  },
  build_requires         => {
    'ExtUtils::XSpp'                  => '0.12',
    'ExtUtils::XSpp::Plugin::Cloning' => '0.01',
  },
  configure_requires     => {
    'ExtUtils::Constant'              => '0',
  },
  # Provides extra C typemaps for opaque objects:
  extra_typemap_modules  => {
    'ExtUtils::Typemap::ObjectMap'    => '0.01',
  },
  extra_linker_flags     => ['-lzmq'],
  extra_compiler_flags   => ['-O2'],
);
$build->create_build_script;


