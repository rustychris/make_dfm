#!/bin/bash 

conda activate dfm_t140737
. /opt/intel/oneapi/setvars.sh intel64

PREFIX=/opt/software/delft/dfm/t140737

export PATH=$PREFIX/bin:$PATH

export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH:$CONDA_PREFIX/lib
export LIBRARY_PATH=$PREFIX/lib:$LIBRARY_PATH:$CONDA_PREFIX/lib
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$CONDA_PREFIX/lib/pkgconfig
export INCLUDE_PATH=$CONDA_PREFIX/include

