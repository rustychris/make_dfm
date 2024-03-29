# make_dfm
Makefile and related for building DFM


# System Prerequisites

## Compiler
Recent versions (last year or so) require intel compilers. Deltares may fix this dependency at some point, but intel is what they use and will presumably continue to be the least troublesome compiler to use. Intel is phasing out the “classic” compilers, but at this point the new compilers are not compatible with the complete process (I think netcdf was the first package to fail with the new compilers). Be sure to install the classic compilers (icc, ifort).

## Supporting Software
The scripts and conda config assume the system already has git, cmake, and pkg-config. 

## DFM Source
If you don’t have a copy of the source you’ll need an open-source login credential (might end with “.x” – mine is rustychris.x). Request from Deltares.

Source code is obtained via svn. The installation manual of each recent version will give a tag name and URL.

Sample checkout:
`svn co https://svn.oss.deltares.nl/repos/delft3d/tags/delft3dfm/140737`

It can take a while to download the first time. Subsequent updates using svn switch are much faster.
 
# Compilation Scripts & Makefile
Clone this repository to get the makefiles, scripts, and patches:

`git clone https://github.com/rustychris/make_dfm`

The scripts also compile some key dependencies. There are two main approaches: with or without conda. 

## Choose With or Without Conda

### Option A: with conda

Conda can be used to provide HDF5 and the base netcdf library (C bindings only). This is particularly useful because together these packages have a long list of dependencies that a barebones system will not include.

Install conda (this can be anaconda, miniconda, or mambaforge). Choose a suitable requirements-*.yml file, copy, and edit to suit your needs. In particular, edit to update the environment name. If cmake does not already exist on the system, add it to the package list.

Create the new environment:
`…/make_dfm$ mamba env create -f requirements-t140737.yml`

(replace mamba with conda if you don’t have mamba installed)

This will install way more stuff than you would imagine is necessary.
 
Edit prepenv.sh. Make sure the 'Option A' section is not commented out and the 'Option B' section is commented. Edit the `conda activate` command to reference the conda environment you just created. By default DFM wil be installed to the same location as the environment (PREFIX=$CONDA_PREFIX), but a different PREFIX can be specified if desired.

### Option B: without conda

The makefiles do include recipes for HDF5 and netcdf, but they do not include recipes for the supporting libraries (e.g. libtiff). You may need to install or compile additional libraries like zlib, libtiff, libjpeg, etc. using a system package manager.

Edit prepenv.sh. Make sure the 'Option A' section is commented and 'Option B' section is not commented. Set the path prefix (PREFIX) for where the builds and binaries will go.

## Intel compilers and other settings
Check path for intel compilers. You may need to update the compiler setup command if Intel oneAPI is installed in a nonstandard place. 

Additional makefile variables beyond the shell variables in prepenv.sh are configurable in Makefile.options.
In particular, the location of the DFM source needs to be set here. Compiler flags (i.e. debugging vs. optimized build) can be set here or in the individual recipes for components (the is not well-organized at the moment).

## Compiling

Start the compilation process by initializing:
`. ./prepenv.sh`

If you’re feeling lucky, the entire process can be run with this:
```
make all
```


More often than not something will go wrong. Going step-by-step can make it easier to figure out what’s broken. If using conda, the
steps are:
```
make build-netcdff (Note ‘ff’ not ‘f’)
make build-mpi
make build-petsc
make build-metis
make build-dfm
```

If *not* using conda
```
make build-hdf5
make build-netcdf
make build-mpi
make build-petsc
make build-metis
make build-dfm
```


To actually use the installation: `. prepenv.sh`
(Alternatively, set LD_LIBRARY_PATH to PREFIX/lib, and reference the executables with full path (or add PREFIX/bin to PATH).
Even if using conda, it is not currently sufficient to only activate the environment. 


If you need to copy the install to a new folder or to a new machine, it might work. You will almost certainly need to add the the …/lib path to LD_LIBRARY_PATH. Conda will embed the installation path into some of the libraries, but LD_LIBRARY_PATH will generally let the system find the libraries in the new path.


 
# Older Notes

## OS X Notes

Sierra and gcc are not compatible for compiling openmpi.  There is some change to
syslog.h, such that it tries to use syslog, but doesn't try to include the header.
There are reports of this error, with no direct fix.


## Patches

There is not currently any attempt to track which patches should be applied to
which dfm versions.

  - r53925-m_tables_workaround.patch: Work around a partial refactoring of the
    m_tables module, should be applied for revisions >=53310

