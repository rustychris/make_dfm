include Makefile.options

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

all: build-hdf5 build-netcdf build-mpi build-petsc build-metis build-dfm


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
	-rm -r $(OMPI_SRC)
	-rm -r $(MPICH_SRC)
	-rm -r $(PETSC_SRC)
	-rm -r $(METIS_SRC)
	-rm -rf $(DFM_SRC)
	-rm -r $(PREFIX)/bin $(PREFIX)/lib $(PREFIX)/include $(PREFIX)/conf $(PREFIX)/etc $(PREFIX)/share

include make.netcdf

# include make.openmpi
include make.mpich

include make.petsc

include make.metis

DFM_BUILD=$(BUILD)/dfm
# DFM_ORIG_SRC will be copied to here
DFM_SRC=$(DFM_BUILD)/src

PKG_CONFIG_PATH=$(PREFIX)/lib/pkgconfig
DFLOWFMROOT=$(PREFIX)

export PKG_CONFIG_PATH DFLOWFMROOT

MPIF90=$(MPI_PREFIX)/bin/mpif90
MPICC=$(MPI_PREFIX)/bin/mpicc 

OPT ?= -O0 -g # debug build
# OPT = -O3

# retain .svn directories to aid in version_number.h
copy-dfm:
	mkdir -p "$(DFM_BUILD)"
	-rm -rf "$(DFM_SRC)"
	rsync -rvlP "$(DFM_ORIG_SRC)/" "$(DFM_SRC)" || (mkdir "$(DFM_SRC)" ; cp -r "$(DFM_ORIG_SRC)"/* "$(DFM_SRC)")

# in previous script FC F77 CC were exported

build-dfm: copy-dfm compile-dfm

# Old rules:
#	FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" $(MAKE) -C $(DFM_SRC) ds-install
#       FC="$(MPIF90)" $(MAKE) -k -C $(DFM_SRC)/engines_gpl/dflowfm ds-install 

compile-dfm:
	cd "$(DFM_SRC)" && FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" ./autogen.sh
	cd "$(DFM_SRC)/third_party_open/kdtree2" && FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" ./autogen.sh
	cd "$(DFM_SRC)" && CFLAGS="$(OPT) -I'$(PREFIX)/include'" CXXFLAGS="$(OPT) -I'$(PREFIX)/include'" METIS_CFLAGS="-I$(PREFIX)/include" FCFLAGS="$(OPT)" FFLAGS="$(OPT)" NETCDF_FORTRAN_CFLAGS="-I$(PREFIX)/include" NETCDF_FORTRAN_LIBS="-L'$(PREFIX)/lib' -lnetcdf -lnetcdff" ./configure --prefix="$(PREFIX)" --with-mpi-dir="$(MPI_PREFIX)" --with-mpi --with-netcdf --with-petsc --with-metis="$(PREFIX)"
	$(MAKE) FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" -C $(DFM_SRC) ds-install
	$(MAKE) FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" -C $(DFM_SRC)/engines_gpl/dflowfm ds-install 

# previous mpi library problems resolved by include --enable-mpi-fortran.

DWAQ_BUILD=$(BUILD)/dwaq
# Rather than checking out code from SVN, use this tree which has a minor bug fix
# no trailing slash
DWAQ_ORIG_SRC=$(HOME)/src/dfm/delft3d-src/delft3d-7545
DWAQ_SRC=$(DWAQ_BUILD)/delft3d

# Seems wasteful to copy .svn over, but the version number script depends on it
copy-dwaq:
	-rm -rf "$(DWAQ_BUILD)" # start clean
	mkdir -p $(DWAQ_BUILD)
	rsync -rvlP --exclude .git $(DWAQ_ORIG_SRC)/ $(DWAQ_SRC)

# At least on OSX, there are some headers in NEFIS which duplicate symbols due to missing
# extern keywords.  This patch fixes that.
# also had to add a define in gp.c for lseek
# Now get an error about malloc.h not found - fixed in jspost.c
patch-dwaq:
	#patch -d "$(DWAQ_SRC)/src/utils_lgpl/nefis/packages/nefis/include/" -p1 < dwaq_externs.patch
	patch -d "$(DWAQ_SRC)/src/utils_lgpl/" -p1 < dwaq_utils_lgpl.patch

# This also requires on OSX installing ossp-uuid, perhaps via brew install ossp-uuid
compile-dwaq: 
	cd "$(DWAQ_SRC)/src" && FC="$(FC)" F77="$(FC)" CC="$(CC)" ./autogen.sh
	cd "$(DWAQ_SRC)/src" && LDFLAGS="$(WAQ_LDFLAGS)" CFLAGS="-O3 -I$(PREFIX)/include" CXXFLAGS="-I$(PREFIX)/include -O3" FCFLAGS=-O3 FFLAGS=-O3 NETCDF_FORTRAN_CFLAGS=-I$(PREFIX)/include NETCDF_FORTRAN_LIBS="-L$(PREFIX)/lib -lnetcdf -lnetcdff" ./configure --prefix=$(PREFIX) --with-netcdf 
	$(MAKE) -C "$(DWAQ_SRC)/src"
	$(MAKE) -C $(DWAQ_SRC)/src install

build-dwaq: copy-dwaq patch-dwaq compile-dwaq

# Ready to test the full process
