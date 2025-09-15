rem
rem Construct windows terminal library
rem
parse syslib=syslib
parse winsup=winsup
rem
rem we need to get a stubbing procedure for this
rem
parse trmlib=trmlib #nrf

rem parse paslib=paslib

ce syslib=syslib
ce winsup=winsup
ce trmlib=trmlib

rem ce paslib=paslib

as wrapper=wrapper
as gettgp=gettgp
as sysovr=sysovr

rem
rem This is actually a stub of the window library,
rem which is not included in the console level library.
rem
ln trmlib=wrapper winsup gettgp sysovr syslib trmlib c:\ip\windows\i80386\lib\paslib
rem
rem Construct the cap cell
rem

as cap=cap
