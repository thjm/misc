#!/bin/bash
#
# build_lede_ffnord.sh
#
# Script to build the Freifunk router software for Gluon with LEDE.
# It is at present based on the ffnord site specifics.
#
##########################################################################
# To run the sript you must make sure that certain packages are installed.
#
# sudo apt-get install git make gcc g++ unzip libncurses5-dev zlib1g-dev \
#              subversion gawk bzip2 libssl-dev wget -y
##########################################################################
#
# References for recipes etc.:
# - https://lede-project.org/docs/guide-developer/quickstart-build-images
# - https://wiki.freifunk.net/Freifunk_Nord/Firmware_selbst_kompilieren
# - https://www.youtube.com/watch?v=l6rw1zo4A2c
#

STARTDIR=`pwd -P`
echo "STARTDIR is $STARTDIR"

# working directory, with date/time specifier
WORKINGDIR="ffnord-$(date '+%Y%m%d-%H%M%S')"
echo "Working directory is $WORKINGDIR"
mkdir $WORKINGDIR
cd $WORKINGDIR

# test for existing patch file
# + user decision to continue without
PATCHFILE="gluon-lede-2017.0.0.patches"
PATCH_URL=$STARTDIR"/"$PATCHFILE
echo "PATCHURL is $PATCH_URL"

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
# For a stable release the SITE_RELEASE must
# be compatible with the GLUON_GIT_RELEASE!
#GLUON_GIT_RELEASE="v2016.2.5"
GLUON_GIT_COMMIT_ID="774d733"
if [ "$GLUON_GIT_RELEASE" != "" ]; then
  GLUON_GIT_RELEASE_DIR="gluon.$GLUON_GIT_RELEASE"
else
  GLUON_GIT_RELEASE_DIR="gluon.$GLUON_GIT_COMMIT_ID"
fi
SITE_RELEASE="nord-lede"
SITE_RELEASE_DIR="site.$SITE_RELEASE"

# number of cores
# (will speedup the things if you have and use multiple cores)
#CORES=1
CORES=$(lscpu|grep -e '^CPU(s):'|xargs|cut -d" " -f2)
if [ $CORES -gt 8 ]; then
  CORES=8
fi

START_TIME=$(date -Iminutes)

# checkout (git clone) the gluon
git clone https://github.com/freifunk-gluon/gluon.git $GLUON_GIT_RELEASE_DIR
cd "$GLUON_GIT_RELEASE_DIR"
if [ "$GLUON_GIT_RELEASE" != "" ]; then
  git checkout -b $GLUON_GIT_RELEASE
else
  git reset --hard $GLUON_GIT_COMMIT_ID
  #git checkout $GLUON_GIT_COMMIT_ID
fi

# checkout the site specific package
git clone https://github.com/Freifunk-Nord/nord-site $SITE_RELEASE_DIR -b $SITE_RELEASE
# set symlink for the Makefile which expects site-specific part in 'site'
ln -s $SITE_RELEASE_DIR site

# get all git-submodules, e.g. lede
make update

# set some vars
GLUON_TARGET=ar71xx-tiny
# ... this is the naming scheme usually used in domain ffka
#GLUON_RELEASE=$SITE_RELEASE-$(date '+%Y%m%d')
GLUON_RELEASE=experimental-$(date '+%Y%m%d')

# 1st build w/o the patch, generates the tool chain -> long running time
#
make -j$CORES GLUON_TARGET=${GLUON_TARGET} GLUON_RELEASE=${GLUON_RELEASE}

# 2nd step is patching, names defined already above
echo "Patch URL is... $PATCH_URL"
if [ -f $PATCH_URL ]
then
  # apply patch
  echo "Patchfile found... $PATCH_URL"
  patch -p1 < $PATCH_URL
  # very important, cleanup the build area first!
  rm -rf lede/tmp
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

# eof


