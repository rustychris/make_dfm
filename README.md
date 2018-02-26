# make_dfm
Makefile and related for building DFM


# OS X Notes

Sierra and gcc are not compatible for compiling openmpi.  There is some change to
syslog.h, such that it tries to use syslog, but doesn't try to include the header.
There are reports of this error, with no direct fix.


