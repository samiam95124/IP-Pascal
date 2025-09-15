rem
rem Construct windows graphical terminal library
rem

rem
rem Plain character version
rem
parse syslib=syslib/nooverflow
parse winsup=winsup/nooverflow
rem
rem we need to get a stubbing procedure for this
rem
parse gralib=gralib/nooverflow

ec syslib=syslib/noc
ec winsup=winsup/noc
rem ec gralib=gralib/noc
ec gralib=gralib/noc/nrc/nac/nclcl

as gettgp=gettgp
as sysovr=sysovr
as getfil=getfil

rem
rem This is actually a stub of the window library,
rem which is not included in the console level library.
rem
rem use this link for debug messages in gralib, because paslib must be initialized to open
rem gralib's debug output.
rem
rem ln gralib=windows winsup gettgp sysovr syslib getfil c:\ip\windows\i80386\lib\paslib gralib/nu
rem
rem Use this link for normal work, because gralib must hook syslib before paslib starts up
rem for proper exit.
rem
ln gralib=windows winsup cpuid cpulock verlock gettgp sysovr syslib getfil gralib c:\ip\windows\i80386\lib\paslib/nu
rem
rem Construct the cap cell
rem

as cap=cap

rem
rem Character encoded version
rem
parse syslib=syslib/nooverflow
parse winsup=winsup/nooverflow
rem
rem we need to get a stubbing procedure for this
rem
parse gralib=gralib/nooverflow

ec syslibx=syslib/noc/scxt
ec winsupx=winsup/noc/scxt
rem ec gralibx=gralib/noc/scxt
ec gralibx=gralib/noc/nrc/nac/nclcl/scxt

as gettgpx=gettgp
as sysovrx=sysovr
as getfilx=getfil

rem
rem This is actually a stub of the window library,
rem which is not included in the console level library.
rem
rem use this link for debug messages in gralib, because paslib must be initialized to open
rem gralib's debug output.
rem
rem ln gralib=windows winsup gettgp sysovr syslib getfil c:\ip\windows\i80386\lib\paslib gralib/nu
rem
rem Use this link for normal work, because gralib must hook syslib before paslib starts up
rem for proper exit.
rem
ln gralibx=windowsx winsupx cpuidx cpulockx verlockx gettgpx sysovrx syslibx getfilx gralibx c:\ip\windows\i80386\lib\paslibx/nu
rem
rem Construct the cap cell
rem

as cap=cap
