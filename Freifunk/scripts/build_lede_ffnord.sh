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

# if set to 1, no build, only work on sources
NO_BUILD=0

STARTDIR=`pwd -P`
echo "STARTDIR is $STARTDIR"

# working directory, with date/time specifier
WORKINGDIR="ffnord-$(date '+%Y%m%d-%H%M%S')"
echo "Working directory is $WORKINGDIR"
mkdir $WORKINGDIR
cd $WORKINGDIR

# Targets and patches
GLUON_TARGETS=""
# test for existing patch files
# + user decision to continue without
# + either the 8mb images are for the tiny or the generic model
PATCHES="gluon-lede-2017.0.0.tl-wr841.patch"
GLUON_TARGETS="$GLUON_TARGETS ar71xx-generic"
PATCHES="$PATCHES gluon-lede-2017.0.0.ar7xxx-generic.patch"
#GLUON_TARGETS="$GLUON_TARGETS ar71xx-tiny"
#PATCHES="$PATCHES gluon-lede-2017.0.0.ar7xxx-tiny.patch"

echo "Checking for patches ..."

HAS_PATCHES=1
for patch in $PATCHES; do

  patch_url=$STARTDIR"/"$patch

  if [ -f $patch_url ]; then
    # patch is available
    echo "Patch $patch_url found... "
  else
    HAS_PATCHES=0
    echo "Patch $patch_url not found..." ;

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

  # don't have to check for other patches
  if [ $HAS_PATCHES -eq 0 ]; then
    break
  fi
done

# define the releases we want to use
#
# For a stable release the SITE_RELEASE must
# be compatible with the GLUON_GIT_RELEASE!
#GLUON_GIT_RELEASE="v2016.2.5"
# commit from 2017-05-04
#GLUON_GIT_COMMIT_ID="774d733"
# commit from  2017-05-17
GLUON_GIT_COMMIT_ID="ad91ab1"
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

# checkout (git clone) the gluon (master version)
git clone https://github.com/freifunk-gluon/gluon.git $GLUON_GIT_RELEASE_DIR
cd "$GLUON_GIT_RELEASE_DIR"
if [ "$GLUON_GIT_RELEASE" != "" ]; then
  # use the tagged version if available
  git checkout -b $GLUON_GIT_RELEASE
else
  # otherwise a fixed state in the repository
  git reset --hard $GLUON_GIT_COMMIT_ID
  #git checkout $GLUON_GIT_COMMIT_ID
fi

# checkout the site specific package
git clone https://github.com/Freifunk-Nord/nord-site $SITE_RELEASE_DIR -b $SITE_RELEASE
# set symlink for the Makefile which expects site-specific part in 'site'
ln -s $SITE_RELEASE_DIR site

# get all git-submodules, e.g. lede
# the file 'modules' specifies the commit IDs, branches or releases
make update

# set some vars
# ... this is the naming scheme usually used in domain ffka
#GLUON_RELEASE=$SITE_RELEASE-$(date '+%Y%m%d')
GLUON_RELEASE=experimental-$(date '+%Y%m%d')

# 1st build w/o the patch, generates the tool chain -> long running time
#
if [ $NO_BUILD -ne 0 ]; then
  echo "Build step 1 skipped!"
else
  for gluon_target in GLUON_TARGETS; do
    make -j$CORES GLUON_TARGET=${gluon_target} GLUON_RELEASE=${GLUON_RELEASE}
    # one $gluon_target is enough
    break
  done
fi

# 2nd step is patching, names defined already above
if [ $HAS_PATCHES -gt 0 ]; then

  for patch in $PATCHES; do
    patch_url=$STARTDIR"/"$patch
    # apply patch
    echo "Applying patchfile $patch_url ..."
    patch -p1 < $patch_url
  done

  # 2nd build with patches
  if [ $NO_BUILD -ne 0 ]; then
    echo "Build step 2 skipped"
  else
    for gluon_target in $GLUON_TARGETS; do
      # very important, cleanup the build area first!
      rm -rf lede/tmp
      # maybe more detailed
      #make GLUON_TARGET=${GLUON_target} GLUON_RELEASE=${GLUON_RELEASE} V=s
      make -j$CORES GLUON_TARGET=${gluon_target} GLUON_RELEASE=${GLUON_RELEASE}
    done
  fi
else
  echo "No Patchfile(s) found...ignoring patchfile"
fi

STOP_TIME=$(date -Iminutes)

echo "Done!"
echo
echo "Start: " $START_TIME
echo "Stop:  " $STOP_TIME

# eof


