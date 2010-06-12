use 5.008;
use ExtUtils::MakeMaker;
use ExtUtils::Constant 'WriteConstants';
use File::Spec;

my $CC = 'g++';

WriteConstants(
  NAME => 'ZeroMQ',
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

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ZeroMQ',
    VERSION_FROM      => 'lib/ZeroMQ.pm', # finds $VERSION
    PREREQ_PM         => {
      'ExtUtils::XSpp' => '0.11',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ZeroMQ.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
    LIBS              => ['-lzmq'], # e.g., '-lm'
    DEFINE            => '-O2', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
     OBJECT            => '$(O_FILES)', # link all the C files too
    'XSOPT'             => '-C++ -hiertype',
    'TYPEMAPS'          => ['perlobject.map'],
    'CC'                => $CC,
    'LD'                => '$(CC)',
    META_MERGE => {
    #  no_index => { directory => 'buildtools', },
      configure_requires => {
        'ExtUtils::Constant' => '0',
      },
    },
    clean => {
      FILES => "const-*.inc",
    },
);


