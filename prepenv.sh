#!/bin/bash 

conda deactivate
. /opt/intel/oneapi/setvars.sh intel64

PREFIX=/opt/software/delft/dfm/t140737

# Stick with mpich.
#export PATH=$PREFIX/bin:/opt/intel/oneapi/mpi/latest/bin:$PATH
export PATH=$PREFIX/bin:$PATH

export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=$PREFIX/lib:$LIBRARY_PATH

