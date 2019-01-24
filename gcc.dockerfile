FROM dockcross/manylinux-x64

# GCC_VERSION is a mandatory argument
ARG GCC_VERSION
RUN test -n "${GCC_VERSION}"
ENV GCC_VERSION ${GCC_VERSION}
ENV objdir /src/objdir
ENV srcdir /src/gcc-${GCC_VERSION}

# Download GCC
WORKDIR /src
RUN yum install -y wget bzip2 \
&&  wget https://mirror.its.dal.ca/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.bz2 \
&&  tar -xvf gcc-${GCC_VERSION}.tar.bz2 \
&&  rm gcc-${GCC_VERSION}.tar.bz2

# Install GCC prerequisites
WORKDIR ${srcdir}
RUN ./contrib/download_prerequisites

# Build and install GCC
WORKDIR ${objdir}
RUN ${srcdir}/configure --prefix=/opt/gcc-${GCC_VERSION} \
        --enable-languages=c,c++,fortran \
        --build=x86_64-linux-gnu --host=x86_64-linux-gnu --target=x86_64-linux-gnu \
        --enable-shared --disable-multilib \
&&  make -j3 bootstrap-lean \
&&  make install

# Only keep what was installed
FROM dockcross/manylinux-x64

ARG GCC_VERSION
RUN test -n "${GCC_VERSION}"
ENV GCC_VERSION ${GCC_VERSION}

COPY --from=0 /opt/gcc-${GCC_VERSION} /opt/gcc-${GCC_VERSION}
RUN echo "/opt/gcc-${GCC_VERSION}/lib64" > /etc/ld.so.conf.d/gcc-${GCC_VERSION}.conf && ldconfig

ENV CC /opt/gcc-${GCC_VERSION}/bin/gcc
ENV CXX /opt/gcc-${GCC_VERSION}/bin/g++
ENV FC /opt/gcc-${GCC_VERSION}/bin/gfortran

# Install OpenMPI
ENV OMPI_VERSION 2.1
ENV OMPI_VERSION_PATCH 6
ENV OMPI openmpi-${OMPI_VERSION}.${OMPI_VERSION_PATCH}
WORKDIR /src
RUN curl -L -o ${OMPI}.tar.gz https://download.open-mpi.org/release/open-mpi/v${OMPI_VERSION}/${OMPI}.tar.gz \
&&  tar -xvf ${OMPI}.tar.gz \
&&  cd ${OMPI} \
&&  ./configure --prefix=/opt/${OMPI} \
&&  make -j3 \
&&  make install \
&&  cd .. && rm -rf openmpi* 

ENV PATH /opt/${OMPI}/bin:${PATH}
ENV LD_LIBRARY_PATH /opt/${OMPI}/lib:${LD_LIBRARY_PATH}

# Install zlib
ENV ZLIB_VERSION 1.2
ENV ZLIB_VERSION_PATCH 11
ENV ZLIB zlib-${ZLIB_VERSION}.${ZLIB_VERSION_PATCH}
WORKDIR /src
RUN curl -L -o ${ZLIB}.tar.gz https://www.zlib.net/${ZLIB}.tar.gz \
&&  tar -xvf ${ZLIB}.tar.gz \
&&  cd ${ZLIB} \
&&  ./configure --prefix=/opt/${HDF5} \
&&  make -j3 \
&&  make install \
&&  cd .. && rm -rf zlib* 

# Install HDF5
ENV HDF5_VERSION 1.10
ENV HDF5_VERSION_PATCH 4
ENV HDF5 hdf5-${HDF5_VERSION}.${HDF5_VERSION_PATCH}
ENV CC mpicc
ENV CXX mpicxx
ENV FC mpifort 
WORKDIR /src
RUN curl -L -o ${HDF5}.tar.bz2 https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_VERSION}/${HDF5}/src/${HDF5}.tar.bz2 \
&&  tar -xjvf ${HDF5}.tar.bz2 \
&&  cd ${HDF5} \
&&  ./configure --prefix=/opt/${HDF5} --with-zlib=/opt/${ZLIB} --enable-parallel \
&&  make -j3 \
&&  make install \
&&  cd .. && rm -rf hdf5*

# Install NetCDF
ENV NC_VERSION 4.6
ENV NC_VERSION_PATCH 2
ENV NC netcdf-c-${NC_VERSION}.${NC_VERSION_PATCH}
ENV CPPFLAGS "-I/opt/${ZLIB}/include -I/opt/${HDF5}/include"
ENV LDFLAGS "-L/opt/${ZLIB}/lib -L/opt/${HDF5}/lib"
WORKDIR /src
RUN curl -L -o ${NC}.tar.gz ftp://ftp.unidata.ucar.edu/pub/netcdf/${NC}.tar.gz \
&&  tar -xzvf ${NC}.tar.gz \
&&  cd ${NC} \
&&  echo --- && ls /usr/local && echo -- \
&&  ./configure --prefix=/opt/${NC} \
&&  make -j3 \
&&  make check \
&&  make install \
&&  cd .. && rm -rf netcdf-c*

RUN echo "/opt/${NC}/lib" > /etc/ld.so.conf.d/${NC}.conf && ldconfig

# Install NetCDF-Fortran
ENV NF_VERSION 4.4
ENV NF_VERSION_PATCH 4
ENV NF netcdf-fortran-${NF_VERSION}.${NF_VERSION_PATCH}
ENV CPPFLAGS "-I/opt/${HDF5}/include -I/opt/${NC}/include"
ENV LDFLAGS "-L/opt/${ZLIB}/lib -L/opt/${HDF5}/lib -L/opt/${NC}/lib"
WORKDIR /src
RUN curl -L -o ${NF}.tar.gz ftp://ftp.unidata.ucar.edu/pub/netcdf/${NF}.tar.gz \
&&  tar -xzvf ${NF}.tar.gz \
&&  cd ${NF} \
&&  echo --- && ls /usr/local && echo -- \
&&  ./configure --prefix=/opt/${NF} \
&&  make -j3 \
&&  make check ; cat nf03_test/test-suite.log \
&&  make install \
&&  cd .. && rm -rf netcdf-fortran*


WORKDIR /src
CMD bash build.sh
