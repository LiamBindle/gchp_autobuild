FROM ubuntu:bionic

ENV GCC_VERSION 5
RUN apt-get update \
&&  apt-get install -y gcc-${GCC_VERSION} g++-${GCC_VERSION} gfortran-${GCC_VERSION} \
                       make cmake git wget bzip2 tar m4 file autoconf automake libtool flex \
                       libcurl4-openssl-dev \
&& update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 100 \
                           --slave /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} \
		           --slave /usr/bin/gfortran gfortran /usr/bin/gfortran-${GCC_VERSION} \
&& update-alternatives --set gcc /usr/bin/gcc-${GCC_VERSION} \
&& dpkg -l | awk '{print $2}' | grep 'gcc' \
&& gcc --version \
&& g++ --version \
&& gfortran --version

# Install OpenMPI
ENV OMPI_VERSION 2.1
ENV OMPI_VERSION_PATCH 6
RUN wget https://download.open-mpi.org/release/open-mpi/v${OMPI_VERSION}/openmpi-${OMPI_VERSION}.${OMPI_VERSION_PATCH}.tar.gz \
&&  tar -xvf openmpi-${OMPI_VERSION}.${OMPI_VERSION_PATCH}.tar.gz \
&&  cd openmpi-${OMPI_VERSION}.${OMPI_VERSION_PATCH} \
&&  ./configure --prefix=/usr/local \
&&  make -j1 \
&&  make install \
&&  cd .. && rm -rf openmpi* 

# Install zlib
ENV ZLIB_VERSION 1.2
ENV ZLIB_VERSION_PATCH 11
RUN wget https://www.zlib.net/zlib-${ZLIB_VERSION}.${ZLIB_VERSION_PATCH}.tar.gz \
&&  tar -xvf zlib-${ZLIB_VERSION}.${ZLIB_VERSION_PATCH}.tar.gz \
&&  cd zlib-${ZLIB_VERSION}.${ZLIB_VERSION_PATCH} \
&&  ./configure --prefix=/usr/local \
&&  make -j1 \
&&  make install \
&&  cd .. && rm -rf zlib* 

# Install HDF5
ENV HDF5_VERSION 1.10
ENV HDF5_VERSION_PATCH 4
RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_VERSION}/hdf5-${HDF5_VERSION}.${HDF5_VERSION_PATCH}/src/hdf5-${HDF5_VERSION}.${HDF5_VERSION_PATCH}.tar.bz2 \
&&  tar -xjvf hdf5-${HDF5_VERSION}.${HDF5_VERSION_PATCH}.tar.bz2 \
&&  cd hdf5-${HDF5_VERSION}.${HDF5_VERSION_PATCH} \
&&  mkdir build && cd build \
&&  cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
          -DZLIB_LIBRARY:FILEPATH=/usr/local/lib/libz.so \
          -DZLIB_INCLUDE_DIR:PATH=/usr/local/include \ 
          -DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=ON \
          .. \
&&  make -j1 \
&&  make install \
&&  cd ../.. && rm -rf hdf5*

# Install NetCDF
ENV NC_VERSION 4.6
ENV NC_VERSION_PATCH 2
RUN wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-c-${NC_VERSION}.${NC_VERSION_PATCH}.tar.gz \
&&  tar -xzvf netcdf-c-${NC_VERSION}.${NC_VERSION_PATCH}.tar.gz \
&&  cd netcdf-c-${NC_VERSION}.${NC_VERSION_PATCH} \
&&  mkdir build && cd build \
&&  cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
          -DCMAKE_PREFIX_PATH=/usr/local \
          .. \
&&  make -j1 \
&&  make install \
&&  cd ../.. && rm -rf netcdf-c*

CMD gcc --version \
&&  g++ --version \
&&  gfortran --version \
&&  mpicc --version \
&&  mpicxx --version \
&&  mpifort --version \
&&  /usr/local/bin/nc-config --all 
