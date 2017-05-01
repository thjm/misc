#!/bin/bash
#
# build_ffka.sh
#
# script to
# - retrieve software for gluon build of site ffka
# - build gluon for site ffka including 8 and 16MB images
#   for TP-Link WR841N/ND
#
##########################################################################
# To run the sript you must make sure that certain packages are installed.
#
# sudo apt-get install git subversion python build-essential gawk unzip \
#               libz-dev libncurses-dev libssl-dev -y
##########################################################################

STARTDIR=`pwd -P`
echo "STARTDIR is $STARTDIR"

# working directory, with date/time specifier
WORKINGDIR="FF-KA-$(date '+%Y%m%d-%H%M%S')"
echo "Working directory is $WORKINGDIR"
mkdir $WORKINGDIR
cd $WORKINGDIR

# test for existing patch file
# + user decision to cintinue without
PATCHFILE="v2016.2.5.patches"
PATCH_URL=$STARTDIR"/"$PATCHFILE
echo "PATCHURL ist $PATCH_URL"

if [ -f $PATCH_URL ]; then
  # patch is available
  echo "Patchfile found... $PATCH_URL"
  echo " and will be used later."
else
  echo "No Patchfile found..." ;
  echo "Press c to continue or any other key to abort..."
  read -n 1 ANSWER
  echo -e "\nYour answer is $ANSWER"
  if [ $ANSWER == "c" ] ; then
    echo "we continue..."
  else
    echo "OK, we abort..."
    exit 1;
  fi
fi

# define the releases we want to use
#
# the SITE_RELEASE must be compatible with the GLUON_GIT_RELEASE!
GLUON_GIT_RELEASE="v2016.2.5"
GLUON_GIT_RELEASE_DIR="gluon.$GLUON_GIT_RELEASE"
SITE_RELEASE="0.3.3-stable.0"
SITE_RELEASE_DIR="site.$SITE_RELEASE"

# number of cores
# (will speedup the things if you have and use multiple cores)
#CORES=1
CORES=$(lscpu|grep -e '^CPU(s):'|xargs|cut -d" " -f2)

START_TIME=$(date -Iminutes)

# checkout (git clone) the gluon
git clone https://github.com/freifunk-gluon/gluon.git $GLUON_GIT_RELEASE_DIR -b $GLUON_GIT_RELEASE
cd "$GLUON_GIT_RELEASE_DIR"

# checkout the site specific package
git clone https://github.com/ffka/site-ffka $SITE_RELEASE_DIR -b $SITE_RELEASE

# set symlink for the Makefile which expects site-specific part in 'site'
ln -s $SITE_RELEASE_DIR site

# get all git-submodules, e.g. openwrt
make update

# set some vars
GLUON_TARGET=ar71xx-generic
# ... this is the naming scheme usually used in domain ffka
GLUON_RELEASE=$SITE_RELEASE-$(date '+%Y%m%d')

# 1st build w/o the path, generates the tool chain -> long running time
#
# some build instructions recommend, to use only one core here
#make -j$CORES GLUON_TARGET=${GLUON_TARGET} GLUON_RELEASE=${GLUON_RELEASE}
make GLUON_TARGET=${GLUON_TARGET} GLUON_RELEASE=${GLUON_RELEASE}

# 2nd step is patching, names defined already above
#PATCHFILE="vvv2016.2.5.patches"
#PATCH_URL=$STARTDIR"/"$PATCHFILE

echo "Patch URL is... $PATCH_URL"
if [ -f $PATCH_URL ]
then
  # apply patch
  echo "Patchfile found... $PATCH_URL"
  patch -p1 < $PATCH_URL
  # 2nd build with patches
  # maybe more detailed
  #make GLUON_TARGET=${GLUON_TARGET} GLUON_RELEASE=${GLUON_RELEASE} V=s
  make -j$CORES GLUON_TARGET=${GLUON_TARGET} GLUON_RELEASE=${GLUON_RELEASE}
else
  echo "No Patchfile found...ignoring patchfile"
fi

STOP_TIME=$(date -Iminutes)

echo "Done!"
echo
echo "Start: " $START_TIME
echo "Stop:  " $STOP_TIME

## eof

