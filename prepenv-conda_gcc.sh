#!/bin/bash 

# . /opt/intel/oneapi/setvars.sh intel64

PREFIX=/opt/software/delft/dfm/t140737

#export PATH=$PREFIX/bin:/opt/intel/oneapi/mpi/latest/bin:$PATH
export PATH=$PREFIX/bin:$PATH
# conda puts itself in LDFLAGS, makes it difficult to avoid linking
# against conda versions of things
unset LDFLAGS
# instead I want to control the order -- still need to find conda libraries.
export LD_LIBRARY_PATH=$PREFIX/lib:$CONDA_PREFIX/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=$PREFIX/lib:$CONDA_PREFIX/lib:$LIBRARY_PATH

