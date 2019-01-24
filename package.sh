#!/bin/bash
set -e
set -x

[ -z $1 ] && echo "No compiler family given" && exit 1
[ -z $2 ] && echo "No compiler version given" && exit 1

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
tar -czvf ../gchp-thirdparty-${1}${2}.tar.gz .
cd ..

rm -rf pkg

