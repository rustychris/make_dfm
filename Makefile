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
	-rm -r $(OMPI_SRC) $(MPICH_SRC)
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
# not sure why, but these copy calls are in some of build scripts, and I think it may
# avoid some compile errors
unpack-dfm:
	mkdir -p "$(DFM_BUILD)"
	-rm -rf "$(DFM_SRC)"
	cp -r "$(DFM_ORIG_SRC)" "$(DFM_SRC)"
	cp $(DFM_SRC)/third_party_open/swan/src/*.[fF]* $(DFM_SRC)/third_party_open/swan/swan_mpi
	cp $(DFM_SRC)/third_party_open/swan/src/*.[fF]* $(DFM_SRC)/third_party_open/swan/swan_omp

# Need a better way to manage patches -- there is a need to track patches which apply to a range
# of subversion revisions.  Currently there are:
# m_tables_workaround: applicable after about 53210
# zbndu: applicable somewhere after 52184, and probably fails much after 53925?
patch-dfm:
	if (svn info $(DFM_ORIG_SRC) | grep 'Revision: 53925' > /dev/null) ; then patch -d $(DFM_SRC) -p1 < r53925-m_tables_workaround.patch ; fi
	if (svn info $(DFM_ORIG_SRC) | grep 'Revision: 53925' > /dev/null) ; then patch -d $(DFM_SRC) -p1 < r53925-zbndu.patch ; fi
	patch -d "$(DFM_SRC)" -p1 < dfm-ugrid-netcdf-r68819.patch
	patch -d "$(DFM_SRC)" -p1 < init-tEcField-pointers-r68819.patch

build-dfm: unpack-dfm patch-dfm compile-dfm

# Tempting to use -finit-local-zero to possibly sidestep some bad code
# that assumes values are initialized. But gfortran is too aggressive
# with this, and it leads to compilation errors.

compile-dfm:
	cd "$(DFM_SRC)" && FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" ./autogen.sh --verbose
	cd "$(DFM_SRC)/third_party_open/kdtree2" && FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" ./autogen.sh
	cd "$(DFM_SRC)" && CFLAGS="$(OPT) -I'$(PREFIX)/include'" CXXFLAGS="$(OPT) -I'$(PREFIX)/include'" METIS_CFLAGS="-I$(PREFIX)/include" FCFLAGS="$(OPT)" FFLAGS="$(OPT)" NETCDF_FORTRAN_CFLAGS="-I$(PREFIX)/include" NETCDF_FORTRAN_LIBS="-L'$(PREFIX)/lib' -lnetcdf -lnetcdff" ./configure --prefix="$(PREFIX)" --with-mpi-dir="$(MPI_PREFIX)" --with-mpi --with-netcdf --with-petsc --with-metis="$(PREFIX)"
	$(MAKE) FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" -C $(DFM_SRC) ds-install
	$(MAKE) FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" -C $(DFM_SRC)/engines_gpl/dflowfm ds-install 


# To recompile after a small edit
recompile-dfm:
	$(MAKE) FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" -C $(DFM_SRC) ds-install
	$(MAKE) FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" -C $(DFM_SRC)/engines_gpl/dflowfm ds-install 

# DWAQ is now part of the regular build
