# Per-build configurable options:
# Root folder where DFM and supporting libraries will be installed.
# will create bin, lib, include, etc. subfolders below here
PREFIX=$(HOME)/src/dfm/r53925-dbg
DFM_ORIG_SRC=$(HOME)/src/dfm-source/unstruc-r53925

CC=gcc
CXX=g++
FC=gfortran

# If this is set to something other than $(PREFIX), use a precompiled
# mpi library
MPI_PREFIX=/share/apps/openmpi-2.1.2/gcc7

# Generally should not need to edit below here

# petsc requires its configure script run by python 2, which on modern
# systems is labeled directly
PYTHON2=python2
F77=$(FC)
BUILD=$(PREFIX)/build

# may have to back off on these for petsc, which wants mpi-*
export PATH := $(PREFIX)/bin:$(PATH)
export CC FC F77 CXX

# figure out what platform we're on
UNAME_S := $(shell uname -s)
UNAME_R := $(shell uname -r)

ifeq ($(UNAME_S),Darwin)
    ifeq ($(UNAME_R),17.3.0)
        SIERRA:=1
    endif
endif

all: build-netcdf46 build-netcdff44 build-openmpi build-petsc build-metis build-dfm

print-%:
	@echo '$*=$($*)'

print-env:
	export

check-compiler:
	@echo Is this at least 4.9?
	@$(CC) -v 2>&1 | grep 'gcc version'

clean:
	-rm -r $(NC_SRC)
	-rm -r $(NCF_SRC)
	-rm -r $(NC46_SRC)
	-rm -r $(NCF44_SRC)
	-rm -r $(OMPI_SRC)
	-rm -r $(PETSC_SRC)
	-rm -r $(METIS_SRC)
	-rm -r $(PREFIX)/{bin,lib,include,conf,etc,share}

NC_BUILD=$(BUILD)/netcdf
NC_TGZ=$(NC_BUILD)/netcdf-4.2.1.tar.gz
NC_SRC=$(NC_BUILD)/netcdf-4.2.1
build-netcdf:
	mkdir -p $(NC_BUILD)
	[ -f $(NC_TGZ) ] || wget -O $(NC_TGZ) ftp://ftp.unidata.ucar.edu/pub/netcdf/old/netcdf-4.2.1.tar.gz
	cd $(NC_BUILD) && tar xzvf netcdf-4.2.1.tar.gz
	cd $(NC_SRC) && ./configure --prefix=$(PREFIX) --disable-netcdf-4 --disable-doxygen --disable-dap
	$(MAKE) -C $(NC_BUILD)/netcdf-4.2.1
	$(MAKE) -C $(NC_BUILD)/netcdf-4.2.1 install

NCF_SRC=$(NC_BUILD)/netcdf-fortran-4.2
NCF_TGZ=$(NC_BUILD)/netcdf-fortran-4.2.tar.gz
build-netcdff: # build-netcdf
	mkdir -p $(NC_BUILD)
	[ -f $(NCF_TGZ) ] || wget -O $(NCF_TGZ) ftp://ftp.unidata.ucar.edu/pub/netcdf/old/netcdf-fortran-4.2.tar.gz
	cd $(NC_BUILD) && tar xzvf netcdf-fortran-4.2.tar.gz
	cd $(NCF_SRC) && FCFLAGS_f90=-Df2cFortran FFLAGS=-Df2cFortran FCFLAGS=-Df2cFortran CPPFLAGS=-I$(PREFIX)/include LDFLAGS=-L$(PREFIX)/lib LD_LIBRARY_PATH=$(PREFIX)/lib ./configure --prefix=$(PREFIX)
	$(MAKE) -C $(NC_BUILD)/netcdf-fortran-4.2
	$(MAKE) -C $(NC_BUILD)/netcdf-fortran-4.2 install


# Trying more recent netcdf:
NC_BUILD=$(BUILD)/netcdf
NC46_TGZ=$(NC_BUILD)/netcdf-4.6.0.tar.gz
NC46_SRC=$(NC_BUILD)/netcdf-c-4.6.0
build-netcdf46:
	mkdir -p $(NC_BUILD)
	[ -f $(NC46_TGZ) ] || wget -O $(NC46_TGZ) https://github.com/Unidata/netcdf-c/archive/v4.6.0.tar.gz
	cd $(NC_BUILD) && tar xzvf $(NC46_TGZ)
	cd $(NC46_SRC) && ./configure --prefix=$(PREFIX) --disable-netcdf-4 --disable-doxygen --disable-dap
	$(MAKE) -C $(NC46_SRC) check install


NCF44_TGZ=$(NC_BUILD)/netcdf-fortran-4.4.4.tar.gz
NCF44_SRC=$(NC_BUILD)/netcdf-fortran-4.4.4
build-netcdff44: 
	mkdir -p $(NC_BUILD)
	[ -f $(NCF44_TGZ) ] || wget -O $(NCF44_TGZ) ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-fortran-4.4.4.tar.gz
	cd $(NC_BUILD) && tar xzvf $(NCF44_TGZ)
	cd $(NCF44_SRC) && CPPFLAGS=-I$(PREFIX)/include LDFLAGS=-L$(PREFIX)/lib LD_LIBRARY_PATH=$(PREFIX)/lib ./configure --prefix=$(PREFIX)
	$(MAKE) -C $(NCF44_SRC)
	$(MAKE) -C $(NCF44_SRC) install

# On OSX Sierra, or at least High Sierra, SYSLOG and gcc are broken.
# Need to intervene to disable SYSLOG
# maybe around line 62603 of configure?
# will it configure and compile with syslog removed from that line?
# https://github.com/open-mpi/ompi/issues/4373
# not as easy as one would think...
# can get some traction by removing syslog and vsyslog in the list of functions to check in
# configure, and then adding to opal_config.h defines for the log levels
# RETURN once the rest of the build works out on OSX
# But this is not bailing on  clang: error: unsupported option '-fopenmp'
# that's in .../ompi/contrib/vt/vt/tools/vtfilter
# This is because it is using g++, not g++-7
# Is setting and exporting CXX above enough to fix that?
# alternatively, can supply --disable-vt to the configure line.
OMPI_BUILD=$(BUILD)/openmpi
OMPI_TGZ=$(OMPI_BUILD)/openmpi-1.10.1.tar.gz
OMPI_SRC=$(OMPI_BUILD)/openmpi-1.10.2

MPI_PREFIX ?= $(PREFIX)
# use this sort of command for the patch:
# diff -crB dir_original dir_updated > dfile.patch

build-openmpi:
	mkdir -p $(OMPI_BUILD)
	[ -f $(OMPI_TGZ) ] || wget -O $(OMPI_TGZ) https://www.open-mpi.org/software/ompi/v1.10/downloads/openmpi-1.10.2.tar.gz
	cd $(OMPI_BUILD) && tar xzvf $(OMPI_TGZ)
	if [ "$(SIERRA)" = "1" ] ; then patch -d $(OMPI_SRC) -p1 < openmpi-sierra.patch ; fi
	# 2016-07-19, added --enable-mpi-fortran here
	cd $(OMPI_SRC) && ./configure --prefix=$(PREFIX) --enable-mpi-fortran --disable-vt
	$(MAKE) -C $(OMPI_BUILD)/openmpi-1.10.2
	$(MAKE) -C $(OMPI_BUILD)/openmpi-1.10.2 install

PETSC_BUILD=$(BUILD)/petsc
PETSC_TGZ=$(PETSC_BUILD)/petsc-3.4.0.tar.gz
PETSC_SRC=$(PETSC_BUILD)/petsc-3.4.0
ifeq ($(UNAME_S),Darwin)
    PETSC_ARCH:=arch-darwin-c-opt
else
    PETSC_ARCH:=arch-linux2-c-opt
endif

fetch-petsc: $(PETSC_TGZ)
$(PETSC_TGZ):
	mkdir -p $(PETSC_BUILD)
	wget -O $(PETSC_TGZ) http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-3.4.0.tar.gz

# PETSC ignore CC,FC,F77, and will warn if they are present.
# it even complains if --with-cc=$(CC) --with-fc=$(FC) are specified
# even clearing their values, it still complains, but does not abort
build-petsc: $(PETSC_TGZ) # build-openmpi
	cd $(PETSC_BUILD) && tar xzvf $(PETSC_TGZ)
	cd $(PETSC_SRC) && CXX= CC= FC= F77= $(PYTHON2) ./configure --prefix=$(PREFIX) --with-mpi-dir=$(MPI_PREFIX) --download-f-blas-lapack=1 --FOPTFLAGS="-xHOST -O3 -no-prec-div" --with-debugging=0 --with-shared-libraries=1 --COPTFLAGS="-O3" 
	$(MAKE) -C $(PETSC_SRC) PETSC_DIR=$(PETSC_SRC) PETSC_ARCH=$(PETSC_ARCH) all
	$(MAKE) -C $(PETSC_SRC) PETSC_DIR=$(PETSC_SRC) PETSC_ARCH=$(PETSC_ARCH) install

METIS_BUILD=$(BUILD)/metis
METIS_TGZ=$(METIS_BUILD)/metis-5.1.0.tar.gz
METIS_SRC=$(METIS_BUILD)/metis-5.1.0
fetch-metis: $(METIS_TGZ)
$(METIS_TGZ):
	mkdir -p $(METIS_BUILD)
	wget -O $(METIS_TGZ) http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz

# make -C silently adds a -w flag, and that confuses the metis sub-make.
# --no-print-directory drops the -w flag for sub-makes, and while it still appears in
# the sub-make's MAKEFLAGS and MFLAGS, perhaps the double-dash avoids issues.
build-metis: $(METIS_TGZ)
	cd $(METIS_BUILD) && tar xzvf $(METIS_TGZ)
	cd $(METIS_SRC) && make config shared=1 cc=$(CC) prefix=$(PREFIX)
	make --no-print-directory -C $(METIS_SRC) all
	make --no-print-directory -C $(METIS_SRC) install

DFM_BUILD=$(BUILD)/dfm
# Rather than checking out code from SVN, use this tree which has a minor bug fix
# NB: trailing slash is added below in rsync command to copy the files inside unstruc
# into the build/dfm/unstruc directory
DFM_SRC=$(DFM_BUILD)/unstruc

PKG_CONFIG_PATH=$(PREFIX)/lib/pkgconfig
DFLOWFMROOT=$(PREFIX)

export PKG_CONFIG_PATH DFLOWFMROOT

MPIF90=$(MPI_PREFIX)/bin/mpif90
MPICC=$(MPI_PREFIX)/bin/mpicc 

OPT = -O0 -g # debug build
# OPT = -O3

build-dfm:
	mkdir -p $(DFM_BUILD)
	rsync -rvlP --exclude .svn $(DFM_ORIG_SRC)/ $(DFM_SRC)
	# in previous script these were exported
	cd $(DFM_SRC) && FC=$(MPIF90) F77=$(MPIF90) CC=$(MPICC) ./autogen.sh
	cd $(DFM_SRC)/third_party_open/kdtree2 && FC=$(MPIF90) F77=$(MPIF90) CC=$(MPICC) ./autogen.sh
	# last time gave -g for all flags
	cd $(DFM_SRC) && CFLAGS="$(OPT)" CXXFLAGS="$(OPT)" METIS_CFLAGS="-I$(PREFIX)/include" FCFLAGS="$(OPT)" FFLAGS="$(OPT)" NETCDF_FORTRAN_CFLAGS=-I$(PREFIX)/include NETCDF_FORTRAN_LIBS="-L$(PREFIX)/lib -lnetcdf -lnetcdff" ./configure --prefix=$(PREFIX) --with-mpi-dir=$(MPI_PREFIX) --with-petsc --with-metis=$(PREFIX)
	$(MAKE) -C $(DFM_SRC)
	$(MAKE) -C $(DFM_SRC) install


# previous mpi library problems resolved by include --enable-mpi-fortran.
