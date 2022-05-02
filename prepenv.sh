#!/bin/bash 

. /share/apps/intel-2019/bin/compilervars.sh intel64
module load cmake
export PATH=/home/rustyh/src/dfm/t140737/bin:$PATH
export LD_LIBRARY_PATH=/home/rustyh/src/dfm/t140737/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=/home/rustyh/src/dfm/t140737/lib:$LIBRARY_PATH

