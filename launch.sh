#!/bin/bash
set -e
set -x


function usage() {
	echo "usage: ./launch.sh <thirdparty|package> <gcc|intel> < version >"
}

[ -z $1 ] && usage && exit 1
[ -z $2 ] && usage && exit 1
[ -z $3 ] && usage && exit 1

TARGET=$1
COMPILER=$2
VERSION=$3

case $TARGET in 
thirdparty|package)
	docker run --rm -v $(pwd):/src -ti gchp_buildenv-${COMPILER}${VERSION} ${TARGET} ${COMPILER} ${VERSION}
	;;
*)
	usage
	;;
esac
