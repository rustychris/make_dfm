include Makefile.options

# Generally should not need to edit below here

# older petsc required its configure script run by python 2
PYTHON2=python2
PYTHON=python

F77=$(FC)
BUILD=$(PREFIX)/build

# may have to back off on these for petsc, which wants mpi-*
export PATH := $(PREFIX)/bin:$(PATH)
export CC FC F77 CXX

# prepping for directly calling dfm cmake
METIS_DIR=$(PREFIX)
export METIS_DIR
export PREFIX

PKG_CONFIG_PATH := $(PREFIX)/lib/pkgconfig:$(PKG_CONFIG_PATH)
export PKG_CONFIG_PATH

# figure out what platform we're on
UNAME_S := $(shell uname -s)
UNAME_R := $(shell uname -r)

ifeq ($(UNAME_S),Darwin)
    ifeq ($(UNAME_R),17.3.0)
        SIERRA:=1
    endif
endif

all: build-hdf5 build-netcdf build-mpi build-petsc build-metis build-dfm

# By default zlib is not built since many systems have it already.
# likewise for proj

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

include make.hdf5
include make.netcdf
include make.zlib
include make.proj


# include make.openmpi
include make.mpich

include make.petsc

include make.metis

DFM_BUILD=$(BUILD)/dfm
# DFM_ORIG_SRC will be copied to here
DFM_SRC=$(DFM_BUILD)/src


DFLOWFMROOT=$(PREFIX)

export DFLOWFMROOT

ifneq (,$(find string 'oneapi' $(MPI_PREFIX)))
  # weirdly, mpif90 would use gfortran
  MPIF90=$(MPI_PREFIX)/bin/mpiifort
  MPICC=$(MPI_PREFIX)/bin/mpicc
else
  MPIF90=$(MPI_PREFIX)/bin/mpif90
  MPICC=$(MPI_PREFIX)/bin/mpicc
endif

OPT ?= -O3

# retain .svn directories to aid in version_number.h
# not sure why, but these copy calls are in some of build scripts, and I think it may
# avoid some compile errors
# Post-reorganization these copies no longer make sense.
unpack-dfm:
	mkdir -p "$(DFM_BUILD)"
	-rm -rf "$(DFM_SRC)"
	cp -r "$(DFM_ORIG_SRC)" "$(DFM_SRC)"
	-cp $(DFM_SRC)/third_party_open/swan/src/*.[fF]* $(DFM_SRC)/third_party_open/swan/swan_mpi
	-cp $(DFM_SRC)/third_party_open/swan/src/*.[fF]* $(DFM_SRC)/third_party_open/swan/swan_omp

# Need a better way to manage patches -- there is a need to track patches which apply to a range
# of subversion revisions.  Currently there are:
# m_tables_workaround: applicable after about 53210
# zbndu: applicable somewhere after 52184, and probably fails much after 53925?
# by 2022.03, no longer applicable
# patch -d "$(DFM_SRC)" -p1 < dfm-ugrid-netcdf-r68819.patch
# patch -d "$(DFM_SRC)" -p1 < init-tEcField-pointers-r68819.patch

patch-dfm:
	if (svn info $(DFM_ORIG_SRC) | grep 'Revision: 53925' > /dev/null) ; then patch -d $(DFM_SRC) -p1 < r53925-m_tables_workaround.patch ; fi
	if (svn info $(DFM_ORIG_SRC) | grep 'Revision: 53925' > /dev/null) ; then patch -d $(DFM_SRC) -p1 < r53925-zbndu.patch ; fi

# and this is only recently (for 2022.03) applicable
# dfm_bmi.patch: issue with length of string arguments.
# sys/sysctl.h: removed in glibc 2.32. Unclear whether this will work
# drop 	'cp build-local.sh "$(DFM_SRC)"' since we don't use it.
patch-dfm-cmake:
	svn patch cmake_use_mpich.patch "$(DFM_SRC)"
	svn patch epshstem.patch "$(DFM_SRC)"
	svn patch dfm_bmi.patch "$(DFM_SRC)"
	[ -d $(PREFIX)/bin ] || mkdir -p $(PREFIX)/bin
	[ -d $(PREFIX)/include/sys ] || mkdir -p $(PREFIX)/include/sys
	which module > /dev/null 2>&1 || cp module-nop.sh $(PREFIX)/bin/module
	touch $(PREFIX)/include/sys/sysctl.h


#build-dfm: unpack-dfm patch-dfm compile-dfm
build-dfm: unpack-dfm patch-dfm patch-dfm-cmake compile-dfm-cmake


# Tempting to use -finit-local-zero to possibly sidestep some bad code
# that assumes values are initialized. But gfortran is too aggressive
# with this, and it leads to compilation errors.

compile-dfm:
	cd "$(DFM_SRC)" && FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" ./autogen.sh --verbose
	cd "$(DFM_SRC)/third_party_open/kdtree2" && FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" ./autogen.sh
	cd "$(DFM_SRC)" && CFLAGS="$(OPT) -I'$(PREFIX)/include'" CXXFLAGS="$(OPT) -I'$(PREFIX)/include'" METIS_CFLAGS="-I$(PREFIX)/include" FCFLAGS="$(OPT)" FFLAGS="$(OPT)" NETCDF_FORTRAN_CFLAGS="-I$(PREFIX)/include" NETCDF_FORTRAN_LIBS="-L'$(PREFIX)/lib' -lnetcdf -lnetcdff" ./configure --prefix="$(PREFIX)" --with-mpi-dir="$(MPI_PREFIX)" --with-mpi --with-netcdf --with-petsc --with-metis="$(PREFIX)"
	$(MAKE) FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" -C $(DFM_SRC) ds-install
	$(MAKE) FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" -C $(DFM_SRC)/engines_gpl/dflowfm ds-install 

# for FARM, before invoking any of this needs
# . /share/apps/intel-2019/bin/compilervars.sh intel64
# module load cmake
compile-dfm-cmake-debug:
	cd "$(DFM_SRC)" && PREFIX=$(PREFIX) CFLAGS="-I$(CONDA_PREFIX)/include" ./build-local.sh dflowfm --debug
	patchelf --add-needed libmetis.so $(DFM_SRC)/build_dflowfm_debug/install/lib/libdflowfm.so

# Had been getting line truncation issues, but this appears to be working.
# The build-local.sh stuff feels unnecessary. It's just wrapping some cmake calls and we're
# better off calling them directly to have more control over the process.

# This is the way using a modified version of their build script:
# compile-dfm-cmake:
# 	cd "$(DFM_SRC)" && PREFIX=$(PREFIX) CFLAGS="-I$(CONDA_PREFIX)/include" FC="$(MPIF90)" FFLAGS="-ffree-line-length-512" ./build-local.sh dflowfm 
# 	patchelf --add-needed libmetis.so $(DFM_SRC)/build_dflowfm/install/lib/libdflowfm.so
# 
# compile-dwaq-cmake:
# 	cd "$(DFM_SRC)" && PREFIX=$(PREFIX) CFLAGS="-I$(CONDA_PREFIX)/include" FC="$(MPIF90)" FFLAGS="-ffree-line-length-512" ./build-local.sh dwaq --debug

DFM_BUILD_SUFFIX=""
DFM_CMAKE_BUILD_DIR=$(DFM_SRC)/build_dflowfm$(DFM_BUILD_SUFFIX)
# Quoting gets weird here. Appears that make will preserve these quotes, so no need
# to quote in dfm_DoCMake.
DFM_GENERATOR="Unix Makefiles"
DFM_BUILDTYPE=Release
DFM_ENV=CFLAGS="-I$(CONDA_PREFIX)/include" FC="$(MPIF90)" CC="$(MPICC)" CXX="$(MPICC)" FFLAGS="-ffree-line-length-512"

# configurationType is "dflowfm"
# This line is the equivalent of build-local.sh dflowfm
compile-dfm-cmake: dfm_CreateCMakedir dfm_DoCMake dfm_BuildCMake dfm_InstallAll

dfm_CreateCMakedir:
	rm -rf $(DFM_CMAKE_BUILD_DIR)
	mkdir  $(DFM_CMAKE_BUILD_DIR)

dfm_DoCMake:
	cd $(DFM_CMAKE_BUILD_DIR) && $(DFM_ENV) cmake -G $(DFM_GENERATOR) -B "." -D CONFIGURATION_TYPE="dflowfm" -D CMAKE_BUILD_TYPE=${DFM_BUILDTYPE} ../src/cmake 

dfm_BuildCMake:
	cd $(DFM_CMAKE_BUILD_DIR) && $(DFM_ENV) make VERBOSE=1 install

dfm_InstallAll:
	echo "makefile does not do the InstallAll business"

#     if [ ${1} = "all"  ]; then
#         echo
#         echo "Installing in build_$1$2 ..."
#         cd     $root
#         rm -rf $root/build_$1$2/lnx64
#         mkdir -p $root/build_$1$2/lnx64/bin
#         mkdir -p $root/build_$1$2/lnx64/lib
#         mkdir -p $root/build_$1$2/lnx64/share/delft3d/esmf/lnx64/bin
#         mkdir -p $root/build_$1$2/lnx64/share/delft3d/esmf/lnx64/bin_COS7
# 
#         # CMaked stuff
#         cp -rf $root/build_$1$2/install/* $root/build_$1$2/lnx64/ &>/dev/null
# 
#         # Additional step to copy ESMF stuff needed by D-WAVES
#         cp -rf $root/src/third_party_open/esmf/lnx64/bin/ESMF_RegridWeightGen                          $root/build_$1$2/lnx64/bin                               &>/dev/null
#         cp -rf $root/src/third_party_open/esmf/lnx64/scripts/ESMF_RegridWeightGen_in_Delft3D-WAVE.sh   $root/build_$1$2/lnx64/bin                               &>/dev/null
#         cp -rf $root/src/third_party_open/esmf/lnx64/bin/lib*                                          $root/build_$1$2/lnx64/share/delft3d/esmf/lnx64/bin      &>/dev/null
#         cp -rf $root/src/third_party_open/esmf/lnx64/bin_COS7/lib*                                     $root/build_$1$2/lnx64/share/delft3d/esmf/lnx64/bin_COS7 &>/dev/null
#     fi

# To recompile after a small edit
recompile-dfm:
	$(MAKE) FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" -C $(DFM_SRC) ds-install
	$(MAKE) FC="$(MPIF90)" F77="$(MPIF90)" CC="$(MPICC)" -C $(DFM_SRC)/engines_gpl/dflowfm ds-install 

recompile-dfm-cmake: dfm_BuildCMake dfm_InstallAll

# DFM build puts everything down some levels. note that this does re-copy a bunch of libraries
# that were copied out of this same place...
# TODO: Really should only copy the libraries that are required. DFM decides to "install"
# every binary dependency it can find.
install-dfm:
	rsync -rvPl --exclude 'libc.*' --exclude 'libc-*.so' $(PREFIX)/build/dfm/src/build_dflowfm/install/ $(PREFIX)

install-dwaq:
	rsync -rvPl --exclude 'libc.*' --exclude 'libc-*.so' $(PREFIX)/build/dfm/src/build_dwaq/install/ $(PREFIX)

install-dwaq-debug:
	rsync -rvPl --exclude 'libc.*' --exclude 'libc-*.so' $(PREFIX)/build/dfm/src/build_dwaq_debug/install/ $(PREFIX)
