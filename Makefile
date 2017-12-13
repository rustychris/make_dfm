#PREFIX=/home/rusty/code/dfm
#PREFIX=/opt/software/delft/dfm/r50237-opt
PREFIX=/opt/software/delft/dfm/r52184-opt
BUILD=$(PREFIX)/build

CC=gcc
FC=gfortran
F77=gfortran

# may have to back off on these for petsc, which wants mpi-*
export PATH := $(PREFIX)/bin:$(PATH)
export CC FC F77

print-%:
	@echo '$*=$($*)'

check-compiler:
	@echo Is this at least 4.9?
	@$(CC) -v 2>&1 | grep 'gcc version'

NC_BUILD=$(BUILD)/netcdf
NCF_TGZ=$(NC_BUILD)/netcdf-fortran-4.2.tar.gz
NC_TGZ=$(NC_BUILD)/netcdf-4.2.1.tar.gz

build-netcdf:
	mkdir -p $(NC_BUILD)
	[ -f $(NC_TGZ) ] || wget -O $(NC_TGZ) ftp://ftp.unidata.ucar.edu/pub/netcdf/old/netcdf-4.2.1.tar.gz
	cd $(NC_BUILD) && tar xzvf netcdf-4.2.1.tar.gz
	cd $(NC_BUILD)/netcdf-4.2.1 && ./configure --prefix=$(PREFIX) --disable-netcdf-4 --disable-doxygen --disable-dap
	$(MAKE) -C $(NC_BUILD)/netcdf-4.2.1
	$(MAKE) -C $(NC_BUILD)/netcdf-4.2.1 install

build-netcdff: # build-netcdf
	mkdir -p $(NC_BUILD)
	[ -f $(NCF_TGZ) ] || wget -O $(NCF_TGZ) ftp://ftp.unidata.ucar.edu/pub/netcdf/old/netcdf-fortran-4.2.tar.gz
	# export FC=gfortran
	# export F77=$FC
	cd $(NC_BUILD) && tar xzvf netcdf-fortran-4.2.tar.gz
	cd $(NC_BUILD)/netcdf-fortran-4.2 && CPPFLAGS=-I$(PREFIX)/include LDFLAGS=-L$(PREFIX)/lib LD_LIBRARY_PATH=$(PREFIX)/lib ./configure --prefix=$(PREFIX)
	$(MAKE) -C $(NC_BUILD)/netcdf-fortran-4.2
	$(MAKE) -C $(NC_BUILD)/netcdf-fortran-4.2 install

OMPI_BUILD=$(BUILD)/openmpi
OMPI_TGZ=$(OMPI_BUILD)/openmpi-1.10.1.tar.gz
build-openmpi:
	mkdir -p $(OMPI_BUILD)
	[ -f $(OMPI_TGZ) ] || wget -O $(OMPI_TGZ) https://www.open-mpi.org/software/ompi/v1.10/downloads/openmpi-1.10.2.tar.gz
	cd $(OMPI_BUILD) && tar xzvf $(OMPI_TGZ)
	# 2016-07-19, added --enable-mpi-fortran here
	cd $(OMPI_BUILD)/openmpi-1.10.2 && ./configure --prefix=$(PREFIX) --enable-mpi-fortran
	$(MAKE) -C $(OMPI_BUILD)/openmpi-1.10.2
	$(MAKE) -C $(OMPI_BUILD)/openmpi-1.10.2 install

PETSC_BUILD=$(BUILD)/petsc
PETSC_TGZ=$(PETSC_BUILD)/petsc-3.4.0.tar.gz
PETSC_SRC=$(PETSC_BUILD)/petsc-3.4.0
# no need to set FC, F77, as it will use mpif90
build-petsc: # build-openmpi
	mkdir -p $(PETSC_BUILD)
	[ -f $(PETSC_TGZ) ] || wget -O $(PETSC_TGZ) http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-3.4.0.tar.gz
	# 2016-07-19: Had been compiling with debugging=0, but after a dflowfm segfault, trying debugging=1
	# 2017-07-10: Back to debugging=0
	cd $(PETSC_BUILD) && tar xzvf $(PETSC_TGZ)
	# PETSC ignore CC,FC,F77, and will warn if they are present.
	cd $(PETSC_SRC) && CC= FC= F77= ./configure --prefix=$(PREFIX) --with-mpi-dir=$(PREFIX) --download-f-blas-lapack=1 --FOPTFLAGS="-xHOST -O3 -no-prec-div" --with-debugging=0 --with-shared-libraries=1 --COPTFLAGS="-O3"
	$(MAKE) -C $(PETSC_SRC) PETSC_DIR=$(PETSC_SRC) PETSC_ARCH=arch-linux2-c-opt all
	$(MAKE) -C $(PETSC_SRC) PETSC_DIR=$(PETSC_SRC) PETSC_ARCH=arch-linux2-c-opt install


DFM_BUILD=$(BUILD)/dfm
# Rather than checking out code from SVN, use this tree which has a minor bug fix
# NB: trailing slash is added below in rsync command to copy the files inside unstruc
# into the build/dfm/unstruc directory
DFM_ORIG_SRC=/home/rusty/code/delft/dfm-linux/unstruc
DFM_SRC=$(DFM_BUILD)/unstruc

PKG_CONFIG_PATH=$(PREFIX)/lib/pkgconfig
DFLOWFMROOT=$(PREFIX)

export PKG_CONFIG_PATH DFLOWFMROOT

# complaining that it can't find petsc..

build-dfm:
	mkdir -p $(DFM_BUILD)
	rsync -rvlP --exclude .svn $(DFM_ORIG_SRC)/ $(DFM_SRC)
	# in previous script these were exported
	cd $(DFM_SRC) && FC=$(PREFIX)/bin/mpif90 F77=$(PREFIX)/bin/mpif90 CC=$(PREFIX)/bin/mpicc ./autogen.sh
	cd $(DFM_SRC)/third_party_open/kdtree2 && FC=$(PREFIX)/bin/mpif90 F77=$(PREFIX)/bin/mpif90 CC=$(PREFIX)/bin/mpicc ./autogen.sh
	# last time gave -g for all flags
	cd $(DFM_SRC) && CFLAGS=-O3 CXXFLAGS=-O3 FCFLAGS=-O3 FFLAGS=-O3 NETCDF_FORTRAN_CFLAGS=-I$(PREFIX)/include NETCDF_FORTRAN_LIBS="-L$(PREFIX)/lib -lnetcdf -lnetcdff" ./configure --prefix=$(PREFIX) --with-mpi-dir=$(PREFIX) --with-petsc --with-metis
	$(MAKE) -C $(DFM_SRC)
	$(MAKE) -C $(DFM_SRC) install


#  --Past Errors--
#  
#  /usr/bin/ld: cannot find -l-L/usr/lib/gcc/x86_64-linux-gnu/4.9
#  copy/paste offending line - okay, reproduce error.
#  add -x to bash invocation - can see that the bad flags are passed to mpif90, so it's
#  a configure or libtool problem.
#  seems to be from deplibs variable
#  in libtool --debug output, it shows up in postdeps
#  somehow postdeps, at the very end of libtool, had several -l entries.
#  manually removing these seems to have helped.
#  
#  # previous mpi library problems resolved by include --enable-mpi-fortran.
