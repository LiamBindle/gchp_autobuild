FROM dockcross/manylinux-x64
ARG GCC_VERSION
# Download GCC
WORKDIR /download
RUN yum install -y wget bzip2 \
&&  wget https://mirror.its.dal.ca/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz \
&&  tar -xvf gcc-${GCC_VERSION}.tar.gz \
&&  cd /download/gcc-${GCC_VERSION} \
&&  ./contrib/download_prerequisites \
&&  mkdir /download/gcc-build && cd /download/gcc-build \
&&  /download/gcc-${GCC_VERSION}/configure --prefix=/opt/gcc-${GCC_VERSION} \
        --enable-languages=c,c++,fortran \
        --build=x86_64-linux-gnu --host=x86_64-linux-gnu --target=x86_64-linux-gnu \
        --enable-shared --disable-multilib \
&&  make -j3 bootstrap-lean \
&&  make install \
&&  echo "/opt/gcc-${GCC_VERSION}/lib64" > /etc/ld.so.conf.d/gcc-${GCC_VERSION}.conf \
&&  ldconfig \
&&  cd .. && rm -rf /download/gcc-*

# Install OpenMPI
ENV CC=/opt/gcc-${GCC_VERSION}/bin/gcc \
    CXX=/opt/gcc-${GCC_VERSION}/bin/g++ \
    FC=/opt/gcc-${GCC_VERSION}/bin/gfortran \
    PATH=/opt/gcc-${GCC_VERSION}/bin:${PATH} \
    OMPI_VERSION=2.1 \
    OMPI_VERSION_PATCH=6 \
    OMPI=openmpi-2.1.6
RUN curl -L -o ${OMPI}.tar.gz https://download.open-mpi.org/release/open-mpi/v${OMPI_VERSION}/${OMPI}.tar.gz \
&&  tar -xvf ${OMPI}.tar.gz \
&&  cd ${OMPI} \
&&  ./configure --prefix=/opt/${OMPI} \
&&  make -j3 \
&&  make install \
&&  cd .. && rm -rf openmpi* \
&&  echo "/opt/${OMPI}/lib" > /etc/ld.so.conf.d/${OMPI}.conf \
&&  ldconfig

# Install zlib
ENV PATH=/opt/${OMPI}/bin:${PATH} \
    ZLIB_VERSION=1.2 \
    ZLIB_VERSION_PATCH=11 \
    ZLIB=zlib-1.2.11
RUN curl -L -o ${ZLIB}.tar.gz https://www.zlib.net/${ZLIB}.tar.gz \
&&  tar -xvf ${ZLIB}.tar.gz \
&&  cd ${ZLIB} \
&&  ./configure --prefix=/opt/${HDF5} \
&&  make -j3 \
&&  make install \
&&  cd .. && rm -rf zlib* 

# Install HDF5
ENV CC=mpicc \
    CXX=mpicxx \
    FC=mpifort \
    HDF5_VERSION=1.10 \
    HDF5_VERSION_PATCH=4 \
    HDF5=hdf5-1.10.4
RUN curl -L -o ${HDF5}.tar.bz2 https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_VERSION}/${HDF5}/src/${HDF5}.tar.bz2 \
&&  tar -xjvf ${HDF5}.tar.bz2 \
&&  cd ${HDF5} \
&&  ./configure --prefix=/opt/${HDF5} --with-zlib=/opt/${ZLIB} --enable-parallel \
&&  make -j3 \
&&  make install \
&&  cd .. && rm -rf hdf5*

# Install NetCDF
ENV NC_VERSION=4.6 \
    NC_VERSION_PATCH=2 \
    NC=netcdf-c-4.6.2 \
    CPPFLAGS="-I/opt/${ZLIB}/include -I/opt/${HDF5}/include" \
    LDFLAGS="-L/opt/${ZLIB}/lib -L/opt/${HDF5}/lib"
RUN curl -L -o ${NC}.tar.gz ftp://ftp.unidata.ucar.edu/pub/netcdf/${NC}.tar.gz \
&&  tar -xzvf ${NC}.tar.gz \
&&  cd ${NC} \
&&  echo --- && ls /usr/local && echo -- \
&&  ./configure --prefix=/opt/${NC} \
&&  make -j3 \
&&  make check \
&&  make install \
&&  cd .. && rm -rf netcdf-c* \
&&  echo "/opt/${NC}/lib" > /etc/ld.so.conf.d/${NC}.conf \
&&  ldconfig

# Install NetCDF-Fortran
ENV NF_VERSION=4.4 \
    NF_VERSION_PATCH=4 \
    NF=netcdf-fortran-4.4.4 \
    CPPFLAGS="-I/opt/${HDF5}/include -I/opt/${NC}/include" \
    LDFLAGS="-L/opt/${ZLIB}/lib -L/opt/${HDF5}/lib -L/opt/${NC}/lib"
RUN curl -L -o ${NF}.tar.gz ftp://ftp.unidata.ucar.edu/pub/netcdf/${NF}.tar.gz \
&&  tar -xzvf ${NF}.tar.gz \
&&  cd ${NF} \
&&  echo --- && ls /usr/local && echo -- \
&&  ./configure --prefix=/opt/${NF} \
&&  make -j3 \
&&  make check ; cat nf03_test/test-suite.log \
&&  make install \
&&  cd .. && rm -rf netcdf-fortran*

# Final edit to path
ENV PATH /opt/${NC}/bin:/opt/${NF}/bin:${PATH}
WORKDIR /src-tmp
ENTRYPOINT cp /src/gchp.patch /src/gchp.version /src/gchp_thirdparty.rc /src-tmp \
&&         bash /src/build_thirdparty.sh gcc ${GCC_VERSION}
