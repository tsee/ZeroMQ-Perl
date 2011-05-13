#!/bin/sh

# must be run from root of the repository

ABSPATH=$(cd ${0%/*} && echo $PWD/${0##*/})
THISDIR=$(dirname $ABSPATH)

[ -z $MAKE ] && MAKE=$(which make)
[ -z $PERL ] && PERL=$(which perl)

echo "Using perl = $PERL, cpanm = $THISDIR/cpanm"

$PERL $THISDIR/cpanm -l extlib Module::Install
$PERL $THISDIR/cpanm -l extlib Module::Install::AuthorTests
$PERL $THISDIR/cpanm -l extlib Module::Install::CheckLib
$PERL $THISDIR/cpanm -l extlib Module::Install::ReadmeFromPod
$PERL $THISDIR/cpanm -l extlib Module::Install::TestTarget
$PERL $THISDIR/cpanm -l extlib Module::Install::XSUtil

$PERL -I$THISDIR/extlib/lib -Mlocal::lib=extlib Makefile.PL
$PERL -I$THISDIR/extlib/lib -Mlocal::lib=extlib $THISDIR/cpanm --installdeps -L extlib .

$MAKE test