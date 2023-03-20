#!/bin/bash 

conda deactivate
. /opt/intel/oneapi/setvars.sh intel64

PREFIX=/opt/software/delft/dfm/t140737

# Stick with mpich.
#export PATH=$PREFIX/bin:/opt/intel/oneapi/mpi/latest/bin:$PATH
# include conda path to get svn, needed for dfm build.
export PATH=$PREFIX/bin:$PATH:/home/rusty/.conda/envs/general_rh/bin

export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=$PREFIX/lib:$LIBRARY_PATH

