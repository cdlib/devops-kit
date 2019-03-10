#!/bin/bash
# @(#) Script to install shibboleth as non-root user

# General build instructions for Shibboleth3:
# https://wiki.shibboleth.net/confluence/display/SP3/LinuxBuild

# Build and install shibboleth service provider as a non-root user. This is
# based on a text "recipe" which wasn't completely documented, e.g. an
# unspecified bug with shibboleth/boost.

# Static analysis via shellcheck. Ignored errors are marked with comments. See
# https://github.com/koalaman/shellcheck/wiki/Ignore

# Directory for all the downloaded tarballs:
SRCDIR=$HOME/src

# Directory for boost and shibboleth installation:
LOCALROOT=$HOME/local
# All the other shib-related tools (xerces, log4shib, etc.) live in here:
SHIBSP_PREFIX=$LOCALROOT/shibboleth-sp


Download ()
{
    # Download (via wget) from a url ($1) into $SRCDIR
    # If $2 is passed, it's assumed to be the output filename.

    # Require: $SRCDIR exists
    if [ ! -d "$SRCDIR" ]; then
	>&2 echo "Error: directory '$SRCDIR' not found"
	return 1
    fi

    # Why did I use -nc below? Document!
    WGET='/usr/bin/wget -nc '
    [ "$2" ] &&	WGET="$WGET --output-document=$2"

    cd "$SRCDIR"	\
	  && $WGET "$1"
}

Unpack ()
{
    # Untar the file specified ($1) into $SRCDIR

    # Require: $SRCDIR exists
    if [ ! -d "$SRCDIR" ]; then
	>&2 echo "Error: directory '$SRCDIR' not found"
	return 1
    fi

    cd "$SRCDIR"		\
	  && tar -zxvf "$1"
}

Build ()
{
    # Build the software in subdirectory $1 using options specified in $2, $3,...

    # Require: $SRCDIR exists
    if [ ! -d "$SRCDIR" ]; then
	>&2 echo "Error: directory '$SRCDIR' not found"
	return 1
    fi
    # Require: $SHIBSP_PREFIX defined; othwise, Bad Things are going to happen.
    if [ -z "$SHIBSP_PREFIX" ]; then
	>&2 echo "Error: SHIBSP_PREFIX not defined"
	return 1
    fi
	
    # Shift off subdir so all remaining arguments can be passed to configure.
    subdir=$SRCDIR/$1
    shift

    # I *want* $@ to be word split in the code below.
    # shellcheck disable=SC2068
    cd "$subdir"					\
	&& ./configure --prefix="$SHIBSP_PREFIX" $@	\
	&& make						\
	&& make install
}


# Ensure directories are present -- In Puppet, make sure modes are correct, etc.
[ ! -d "$SRCDIR" ] && mkdir -v "$SRCDIR"
[ ! -d "$LOCALROOT" ] && mkdir -v "$LOCALROOT"

# Come back to current directory on error, or after completion. ENTRY_DIR
# doesn't change, and due to subprocesses the variable may not be in scope, so
# disable shell check for single-quoted varaible in the trap command.
ENTRY_DIR=$PWD
# shellcheck disable=SC2064
trap "cd $ENTRY_DIR; exit 1" 1 2 3 15


# Grab "boost" zipfile -- doesn't get built, just unzip in $LOCALROOT
# NOTE: "versions above 1.52 will not work due to a bug in Shibboleth"
# **Which bug?!?** Has it been reported? Is this still a problem?
BOOST_DIRNAME=boost_1_52_0
BOOSTZIP=${BOOST_DIRNAME}.zip
Download http://sourceforge.net/projects/boost/files/boost/1.52.0/boost_1_52_0.zip/download $BOOSTZIP
cd "$LOCALROOT"				\
      && unzip "$SRCDIR/$BOOSTZIP"


# https://shibboleth.net/downloads/log4shib/latest/ currently points to
# https://shibboleth.net/downloads/log4shib/latest/log4shib-2.0.0.tar.gz
THE_URLPATH=https://shibboleth.net/downloads/log4shib/2.0.0
THE_DIRNAME=log4shib-2.0.0
THE_TARBALL=${THE_DIRNAME}.tar.gz
THE_OPTIONS="--disable-static --disable-doxygen"
Download $THE_URLPATH/$THE_TARBALL
Unpack $THE_TARBALL
# I want word splitting on THE_OPTIONS, so disable shell check.
# shellcheck disable=SC2086
Build $THE_DIRNAME $THE_OPTIONS

# https://www.zlib.net/zlib-1.2.11.tar.gz
THE_URLPATH=https://www.zlib.net
THE_DIRNAME=zlib-1.2.11
THE_TARBALL=${THE_DIRNAME}.tar.gz
THE_OPTIONS=""
Download $THE_URLPATH/$THE_TARBALL
Unpack $THE_TARBALL
Build $THE_DIRNAME $THE_OPTIONS

# shibboleth.net suggests building openssl here
# but it's already done?

# https://curl.haxx.se/download/curl-7.64.0.tar.gz
# Why is curl built --with-openssl=/usr/BIN/openssl
# whereas others are built --with-openssl=/usr/INCLUDE/openssl?
THE_URLPATH=https://curl.haxx.se/download
THE_DIRNAME=curl-7.64.0
THE_TARBALL=${THE_DIRNAME}.tar.gz
THE_OPTIONS="--disable-static --enable-thread --without-ca-bundle --with-openssl=/usr/bin/openssl"
Download $THE_URLPATH/$THE_TARBALL
Unpack $THE_TARBALL
# I want word splitting on THE_OPTIONS, so disable shell check.
# shellcheck disable=SC2086
Build $THE_DIRNAME $THE_OPTIONS

# http://apache.mirrors.tds.net/xerces/c/3/sources/xerces-c-3.2.2.tar.gz
THE_URLPATH=http://apache.mirrors.tds.net/xerces/c/3/sources
THE_DIRNAME=xerces-c-3.2.2
THE_TARBALL=${THE_DIRNAME}.tar.gz
THE_OPTIONS="--enable-netaccessor-socket"
Download $THE_URLPATH/$THE_TARBALL
Unpack $THE_TARBALL
# I want word splitting on THE_OPTIONS, so disable shell check.
# shellcheck disable=SC2086
Build $THE_DIRNAME $THE_OPTIONS

# http://mirrors.gigenet.com/apache/santuario/c-library/xml-security-c-2.0.2.tar.gz
THE_URLPATH=http://mirrors.gigenet.com/apache/santuario/c-library
THE_DIRNAME=xml-security-c-2.0.2
THE_TARBALL=${THE_DIRNAME}.tar.gz
THE_OPTIONS="--without-xalan --disable-static"
# --with-xerces is no longer an option for shib3; instead, use
# PKG_CONFIG_PATH to tell xml-security-c where to find xerces.
# This needs to be exported in order to work within Build function.
export PKG_CONFIG_PATH="$SHIBSP_PREFIX/lib/pkgconfig"
Download $THE_URLPATH/$THE_TARBALL
Unpack $THE_TARBALL
# I want word splitting on THE_OPTIONS, so disable shell check.
# shellcheck disable=SC2086
Build $THE_DIRNAME $THE_OPTIONS

exit

# http://shibboleth.net/downloads/c++-opensaml/2.5.3/xmltooling-1.5.3.tar.gz
THE_URLPATH=http://shibboleth.net/downloads/c++-opensaml/2.5.3
THE_DIRNAME=xmltooling-1.5.3
THE_TARBALL=${THE_DIRNAME}.tar.gz
THE_OPTIONS="--with-log4shib=$SHIBSP_PREFIX --with-curl=$SHIBSP_PREFIX --with-boost=$LOCALROOT/$BOOST_DIRNAME --with-openssl=/usr/include/openssl"
Download $THE_URLPATH/$THE_TARBALL
Unpack $THE_TARBALL
# I want word splitting on THE_OPTIONS, so disable shell check.
# shellcheck disable=SC2086
Build $THE_DIRNAME $THE_OPTIONS

# http://shibboleth.net/downloads/c++-opensaml/2.5.3/opensaml-2.5.3.tar.gz
THE_URLPATH=http://shibboleth.net/downloads/c++-opensaml/2.5.3
THE_DIRNAME=opensaml-2.5.3
THE_TARBALL=${THE_DIRNAME}.tar.gz
THE_OPTIONS="--with-log4shib=$SHIBSP_PREFIX --with-boost=$LOCALROOT/$BOOST_DIRNAME --with-openssl=/usr/include/openssl"
Download $THE_URLPATH/$THE_TARBALL
Unpack $THE_TARBALL
# I want word splitting on THE_OPTIONS, so disable shell check.
# shellcheck disable=SC2086
Build $THE_DIRNAME $THE_OPTIONS

# http://shibboleth.net/downloads/service-provider/latest/shibboleth-sp-2.6.0.tar.gz not building--dependencies?
### THE_URLPATH=http://shibboleth.net/downloads/service-provider/latest
### THE_DIRNAME=shibboleth-sp-2.6.0

# http://shibboleth.net/downloads/service-provider/latest/shibboleth-sp-2.5.5.tar.gz not found, fix URLPATH
THE_URLPATH=http://shibboleth.net/downloads/service-provider/2.5.5
THE_DIRNAME=shibboleth-sp-2.5.5
THE_TARBALL=${THE_DIRNAME}.tar.gz
THE_OPTIONS="--with-log4shib=$SHIBSP_PREFIX --with-boost=$LOCALROOT/$BOOST_DIRNAME"
Download $THE_URLPATH/$THE_TARBALL
Unpack $THE_TARBALL
# I want word splitting on THE_OPTIONS, so disable shell check.
# shellcheck disable=SC2086
Build $THE_DIRNAME $THE_OPTIONS

# Done, return to starting directory and exit successfully.
cd "$ENTRY_DIR" && exit 0
# else...
>&2 echo "Error: unable to 'cd $ENTRY_DIR'"
exit 1
