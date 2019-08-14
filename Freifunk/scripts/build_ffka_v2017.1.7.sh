#!/bin/bash
#
# build_ffka_v2017.1.7.sh
#
# Script to
# - retrieve software for gluon (LEDE) build of site ffka
# - build gluon for site ffka including 8 and 16MB images
#   for TP-Link WR841N/ND
#

export GLUON_CHECKOUT=v2017.1.7

git clone git://github.com/freifunk-gluon/gluon.git v2017.1.7

cd v2017.1.7
git checkout $GLUON_CHECKOUT

git clone https://gitlab.ffka.tech/firmware/site site

# output from (cd site; git log --oneline; cd ..)
#
#05b3b25 update localizations again
#f72d897 fix translations
#604fe51 fixup gluon-config-mode:reboot again
#cecc60a fixup "gluon-config-mode:reboot"
#559f9a8 !Fixup
#64e9b5e Update to gluon v2017.1.8
#fc8676f add extra Prefixes
#3013e18 update OPKG path
#f0d92d7 Merge remote-tracking branch 'origin/master'
#6fdca83 Update gluon v2017.1.7
#1e5da15 Merge remote-tracking branch 'origin/master'
#b56edbb Update Reboot Message
#6b28d08 update to gluon 2017.1.6
#0d220bf Merge branch 'gluon-experimental' into 'master'
#0e98305 DEFAULT_GLUON_CHECKOUT := v2017.1.5

# v2017.1.5
#(cd site; git checkout 0d220bf; cd ..)
# v2017.1.7
(cd site; git checkout 6fdca83; cd ..)
make update

# remove old images
rm -vrf images/factory images/sysupgrade

# variables to be set by build.sh etc.
export COMMIT_DESCRIPTION=0.5.1-stable.0-6fdca83
#export GLUON_CHECKOUT=v2017.1.7 # see above

export GLUON_RELEASE=0.5.1-stable.0-20181001
export GLUON_BRANCH=experimental
export GLUON_PRIORITY=1

export GLUON_TARGET=ar71xx-generic

# probably not needed, partly done already above
#git checkout $GLUON_CHECKOUT
#git pull origin $GLUON_CHECKOUT

# patching ...
patch -p1 < ../gluon-lede-2017.1.5.ar7xxx-generic.patch
patch -p1 < ../gluon-lede-2017.1.5.tl-wr841.patch

# any new build must start from here
rm -rf lede/tmp
make GLUON_TARGET=$GLUON_TARGET GLUON_RELEASE=$GLUON_RELEASE -j4

## clean it finally, before a new build
#make clean GLUON_TARGET=$GLUON_TARGET
#make dirclean
