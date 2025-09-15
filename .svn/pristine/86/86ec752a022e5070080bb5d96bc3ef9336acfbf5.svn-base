rem
rem Construct windows network library
rem

rem
rem Plain character version
rem
parse syslib=syslib/nooverflow
parse winsup=winsup/nooverflow
rem
rem we need to get a stubbing procedure for this
rem
parse netlib=netlib/nooverflow

ec syslib=syslib/noc
ec winsup=winsup/noc
rem ec netlib=netlib/noc
ec netlib=netlib/noc/nrc/nac/nclcl

as gettgp=gettgp
as sysovr=sysovr
as getfil=getfil

rem
rem This is actually a stub of the window library,
rem which is not included in the console level library.
rem
rem use this link for debug messages in netlib, because paslib must be initialized to open
rem netlib's debug output.
rem
rem ln netlib=windows winsup gettgp sysovr syslib getfil c:\ip\windows\i80386\lib\paslib netlib/nu
rem
rem Use this link for normal work, because netlib must hook syslib before paslib starts up
rem for proper exit.
rem
ln netlib=windows winsup cpuid cpulock verlock gettgp sysovr syslib getfil netlib c:\ip\windows\i80386\lib\paslib/nu
rem
rem Construct the cap cell
rem

as cap=cap
