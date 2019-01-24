#!/bin/bash
set -e
set -x


function usage() {
	echo "usage: ./build.sh <container|thirdparty|package> <gcc|intel> < version >"
}

[ -z $1 ] && usage && exit 1
[ -z $2 ] && usage && exit 1
[ -z $3 ] && usage && exit 1

TARGET=$1
COMPILER=$2
VERSION=$3

function build_container() {
	case $COMPILER in
	gcc)
		docker build --rm -f gcc.dockerfile --build-arg GCC_VERSION=${VERSION} -t gchp_buildenv-gcc${VERSION} .
		;;
	intel)
		docker build --rm -f intel.dockerfile -t gchp_buildenv-intel${VERSION} .
		;;
	*)
		echo "Compiler must be either gcc or intel" && exit 1
		;;
	esac
}

function build_thirdparty() {
	source vars.rc

	# Build ESMF
	if [ ! -f esmf.install ]; then
		cd $ESMF_DIR
		make
		make install 
		cd ..
		touch esmf.install 
	fi

	# Build MAPL
	if [ ! -f mapl.install ]; then
		cd $ESMADIR 
		make --no-print-directory install 
		cd ..
		touch mapl.install 
	fi

	# Build FVdycore
	if [ ! -f fvdycore.install ]; then
		cd $FV_DIR
		make --no-print-directory esma_install 
		cd ..
		touch fvdycore.install 
	fi

	# Build Registry
	if [ ! -f registry.install ]; then
		cd $REG_DIR
		$ESMADIR/MAPL_Base/mapl_acg.pl -v Chem_Registry.rc
		$ESMADIR/MAPL_Base/mapl_acg.pl -v HEMCO_Registry.rc
		cd ..
		touch registry.install 
	fi
}

function build_package() {
	source vars.rc

	rm -rf pkg pkg.tar.gz
	mkdir pkg
	mkdir pkg/include
	mkdir pkg/lib

	find ${ESMADIR}/Linux -type f -name '*.a' | while read lib
	do 
		cp $lib pkg/lib
	done

	find ${ESMADIR}/Linux -type f -name '*.mod' | while read includes
	do 
		cp $includes pkg/include
	done

	find ${ESMADIR}/Linux -type f -name '*.h' | while read includes
	do 
		cp $includes pkg/include
	done

	find ${ESMADIR}/Linux -type f -name '*.inc' | while read includes
	do 
		cp $includes pkg/include
	done

	cp $REG_DIR/*.h pkg/include

	cd pkg
	tar -czvf ../gchp-thirdparty-${COMPILER}${VERSION}.tar.gz .
	cd ..

	rm -rf pkg
}

case $TARGET in
container)
	build_container
	;;
package)
	build_package
	;;
thirdparty)
	build_thirdparty
	;;
*)
	usage
	;;
esac
