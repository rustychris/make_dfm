#!/bin/bash 

conda activate dfm_t141798
. /opt/intel/oneapi/setvars.sh intel64

# Conda doesn't necessarily add this.
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$CONDA_PREFIX/lib/pkgconfig

# Once tested, this could be the conda prefix.
PREFIX=$CONDA_PREFIX
# During development can be cleaner to keep prefix separate.
# PREFIX=/opt/software/delft/dfm/t141798
# export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH
# export LIBRARY_PATH=$CONDA_PREFIX/lib:$LIBRARY_PATH


export PATH=$PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=$PREFIX/lib:$LIBRARY_PATH

# This was in an older attempt, not sure if it's still necessary.
export INCLUDE_PATH=$CONDA_PREFIX/include

