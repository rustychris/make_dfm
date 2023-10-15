#!/bin/bash 


# Option A: Use conda. Activate here:
conda activate dfm_t141798opt
export PREFIX=$CONDA_PREFIX
# End option A

# Option B: Without conda. Make sure no conda environment is active.
# while [ ! -z $CONDA_PREFIX ]; do conda deactivate; done
# export PREFIX=CHOOSE_A_FOLDER
# End option B

# Configure Intel compilers
. /opt/intel/oneapi/setvars.sh intel64

# ----------- Shouldn't need to change things below here ---------------

if [ ! -z "$CONDA_PREFIX" ] ; then
    # Conda doesn't necessarily add this.
    export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$CONDA_PREFIX/lib/pkgconfig
    # This was in an older attempt, not sure if it's still necessary.
    export INCLUDE_PATH=$CONDA_PREFIX/include
fi


if [ ! -z "$CONDA_PREFIX" ] ; then
    if [ "$CONDA_PREFIX" != "$PREFIX" ] ; then
       export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH
       export LIBRARY_PATH=$CONDA_PREFIX/lib:$LIBRARY_PATH
       # Only the c library comes from conda. We compile our own fortran bindings.
       export NETCDFC_PREFIX=$CONDA_PREFIX
    fi
fi

export PATH=$PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=$PREFIX/lib:$LIBRARY_PATH


