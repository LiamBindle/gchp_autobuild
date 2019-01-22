FROM ubuntu:bionic

ENV GCC_VERSION 5
RUN apt-get update \
&&  apt-get install -y make cmake git \
	               wget bzip2 tar m4 file \
	               gcc-${GCC_VERSION} g++-${GCC_VERSION} gfortran-${GCC_VERSION} \
&& update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 100 \
                           --slave /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} \
		           --slave /usr/bin/gfortran gfortran /usr/bin/gfortran-${GCC_VERSION} \
&& update-alternatives --auto gcc

# Install HDF5
ENV HDF5_VERSION 1.10
ENV HDF5_VERSION_PATCH 4
RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_VERSION}/hdf5-${HDF5_VERSION}.${HDF5_VERSION_PATCH}/src/hdf5-${HDF5_VERSION}.${HDF5_VERSION_PATCH}.tar.bz2 && \
    tar -xjvf hdf5-${HDF5_VERSION}.${HDF5_VERSION_PATCH}.tar.bz2
RUN cd hdf5-${HDF5_VERSION}.${HDF5_VERSION_PATCH} && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/hdf5 .. && \
    make -j && \
    make install && \
    cd ../.. && rm -rf hdf5*

# Install NetCDF
ENV NC_VERSION 4.6
ENV NV_VERSION_PATCH 2
RUN wget -O netcdf.tar.gz ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-${NC_VERSION}.${NC_VERSION_PATCH}.tar.gz && \
    tar -xzvf netcdf-${NC_VERSION}.${NC_VERSION_PATCH}.tar.gz
RUN cd netcdf-${NC_VERSION}.${NC_VERSION_PATCH} && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/netcdf -DCMAKE_PREFIX_PATH=/usr/local/hdf5 .. && \
    make -j && \
    make install && \
    cd ../.. && rm -rf netcdf*

CMD update-alternatives --set gcc /usr/bin/gcc-6 && \
	gcc --version && g++ --version && gfortran --version && \
	update-alternatives --set gcc /usr/bin/gcc-7 && \
		gcc --version && g++ --version && gfortran --version && \
	/usr/local/netcdf/bin/nc-config --all
