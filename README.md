# make_dfm
Makefile and related for building DFM


# OS X Notes

Sierra and gcc are not compatible for compiling openmpi.  There is some change to
syslog.h, such that it tries to use syslog, but doesn't try to include the header.
There are reports of this error, with no direct fix.


# Patches

There is not currently any attempt to track which patches should be applied to
which dfm versions.

  - r53925-m_tables_workaround.patch: Work around a partial refactoring of the
    m_tables module, should be applied for revisions >=53310
    