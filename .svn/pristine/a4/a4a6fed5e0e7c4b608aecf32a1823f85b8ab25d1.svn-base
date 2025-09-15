@echo off
rem
rem Compile a program for use with the ansi level library
rem
parse %1=%1 %2 %3 %4 %5 %6 %7 %8 %9 #nrf
ce %1=%1
ln runfile=anslib %1 cap #ps=$401000 #vs=$410000 #lv #ll #lm > %1.loc
genpe %1=runfile kernel32 user32 /v
del runfile.*
