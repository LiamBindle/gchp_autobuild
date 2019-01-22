#!/bin/bash
set -e
set -x

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
tar -czvf ../gchp-thirdparty.tar.gz .
cd ..

rm -rf pkg
