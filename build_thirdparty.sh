#!/bin/bash
set -x
set -e

# Clone and patch GCHP
if [ ! -d gchp ]; then
	git clone https://github.com/geoschem/gchp.git
	cd gchp
	git checkout $(cat ../gchp.version)
	git apply ../gchp.patch
	cd ..
fi

cd gchp
# Build GCHP third party libs
source ../gchp_thirdparty.rc
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
	make --no-print-directory install ESMA_FC=gfortran
	cd ..
	touch mapl.install 
fi
# Build FVdycore
if [ ! -f fvdycore.install ]; then
	cd $FV_DIR
	make --no-print-directory esma_install ESMA_FC=gfortran
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

# Build package
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
tar -czpvf ../gchp_thirdparty-${1}${2}.tar.gz .
cd ..
rm -rf pkg
