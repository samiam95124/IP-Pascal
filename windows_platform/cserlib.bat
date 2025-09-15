rem
rem Construct serial library
rem
rem Creates the serial level library. This library performs all file I/O
rem via the standard I/O calls, and creates programs suitable for run under
rem the Win95 console shell.
rem

rem
rem Plain character version
rem
parse syslib=syslib/nooverflow
parse winsup=winsup/nooverflow
parse verlock=verlock
parse cpulock=cpulock

ec syslib=syslib  /noc/nurl/nfco/ndce/nb2j/nrur/nsls/nrc/nac
ec winsup=winsup
ec verlock=verlock
ec cpulock=cpulock

as gettgp=gettgp
as sysovr=sysovr
as cpuid=cpuid

rem this should work ln serlib=wrapper winsup gettgp sysovr syslib ..\..\common_libraries\paslib
ln serlib=windows winsup cpuid cpulock verlock gettgp sysovr syslib \projects\pascomp\common_libraries\paslib/nu
rem
rem Construct the cap cell
rem
as cap=cap

rem
rem Character encoded version
rem
parse syslib=syslib/nooverflow
parse winsup=winsup/nooverflow
parse verlock=verlock
parse cpulock=cpulock

ec syslibx=syslib/scxt
ec winsupx=winsup/scxt
ec verlockx=verlock/scxt
ec cpulockx=cpulock/scxt

as gettgpx=gettgp
as sysovrx=sysovr
as cpuidx=cpuid

rem this should work ln serlib=wrapper winsup gettgp sysovr syslib ..\..\common_libraries\paslib
ln serlibx=windowsx winsupx cpuidx cpulockx verlockx gettgpx sysovrx \projects\pascomp\common_libraries\xltlib syslibx \projects\pascomp\common_libraries\paslibx/nu
rem
rem Construct the cap cell
rem
as cap=cap
