#!/bin/bash 

# . /share/apps/intel-2019/bin/compilervars.sh intel64
module unload cmake
# after the upgrade, maybe this is the way?
module load intel-oneapi-compilers
module unload openmpi

conda activate general
PREFIX=$CONDA_PREFIX


# export PATH=$PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=$PREFIX/lib:$LIBRARY_PATH

# If using conda to supply dependencies:
export INCLUDE_PATH=$CONDA_PREFIX/include

