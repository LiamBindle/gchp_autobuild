#!/bin/bash
set -e
set -x


function usage() {
	echo "usage: ./buildenv.sh <gcc|intel> < version >"
}

[ -z $1 ] && usage && exit 1
[ -z $2 ] && usage && exit 1

FAMILY=$1
VERSION=$2

docker build --rm --build-arg GCC_VERSION=${VERSION} -t gchp_buildenv-gcc${VERSION} .
docker run --rm -v $(pwd):/src -e GCC_VERSION=${VERSION} --name build_thirdparty-${FAMILY}${VERSION} gchp_buildenv-gcc${VERSION}

