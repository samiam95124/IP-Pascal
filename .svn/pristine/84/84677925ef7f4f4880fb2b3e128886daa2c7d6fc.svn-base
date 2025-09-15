rem
rem Construct windows terminal library for console mode
rem
parse syslib=syslib/nooverflow
parse winsup=winsup/nooverflow
rem
rem we need to get a stubbing procedure for this
rem
parse conlib=conlib/nooverflow

ec syslib=syslib/noc
ec winsup=winsup/noc
ec conlib=conlib/noc

as gettgp=gettgp
as sysovr=sysovr

rem
rem This is actually a stub of the window library,
rem which is not included in the console level library.
rem
ln conlib=windows winsup gettgp sysovr syslib conlib c:\ip\windows\i80386\lib\paslib
rem
rem Construct the cap cell
rem

as cap=cap
