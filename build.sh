#!/bin/bash
set -e
set -x

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

