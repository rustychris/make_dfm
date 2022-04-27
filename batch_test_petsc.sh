#!/bin/bash -l
#SBATCH --job-name petsc
#SBATCH -o petsc_test-%j.output
#SBATCH -e petsc_test-%j.output
#SBATCH --partition high2
#SBATCH -n 8
#SBATCH -N 1
#SBATCH --time 00-06:00:00

. /share/apps/intel-2019/bin/compilervars.sh intel64

PREFIX=/home/rustyh/src/dfm/t140737
export PATH=$PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=$PREFIX/lib:$LIBRARY_PATH

make check-petsc

