rem
rem Construct ansi terminal library
rem
rem Creates the ansi terminal level library. Provides a terminal level library
rem via ANSI screen control calls. Suitable for running under the Win95 console
rem shell, theoretically also via a serial port connection to an ANSI mode
rem terminal.
rem
parse syslib=syslib
rem
rem we need to get a stubbing procedure for this
rem
parse ansilib=ansilib #nrf
parse paslib=paslib
parse winsup=winsup
ce syslib=syslib
ce ansilib=ansilib
ce paslib=paslib
ce winsup=winsup
rem as wrapper=wrapper
as gettgp=gettgp
as sysovr=sysovr
ln anslib=wrapper winsup gettgp sysovr syslib ansilib paslib
rem
rem Construct the cap cell
rem
as cap=cap
