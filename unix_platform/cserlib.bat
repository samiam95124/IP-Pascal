rem
rem Construct serial library
rem
rem Creates the serial level library. This library performs all file I/O
rem via the standard I/O calls, and creates programs suitable for run under
rem A Unix console shell.
rem
as linux386=linux386
copy linux386.obj wrapper.obj
copy linux386.sym wrapper.sym
as gettp386=gettp386
copy gettp386.obj gettgp.obj
copy gettp386.sym gettgp.sym
as sysov386=sysov386
copy sysov386.obj sysovr.obj
copy sysov386.sym sysovr.sym
as cap386=cap386
copy cap386.obj cap.obj
copy cap386.sym cap.sym
parse syslib=syslib
ce syslib=syslib
parse unixsup=unixsup
ce unixsup=unixsup
ln serlib=wrapper gettgp sysovr unixsup syslib ..\comlib\paslib
