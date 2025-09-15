rem @echo off
rem
rem Compile a program for use with the serial level library
rem
parse strtst=strtst
ec strtst=strtst
ln runfile=c:\pascomp\windows\serlib c:\pascomp\comlib\strlib c:\ip\windows\i80386\lib\main strtst c:\ip\windows\i80386\lib\cap/nu
genpe strtst=runfile c:\windows\system32\kernel32 c:\windows\system32\user32 c:\windows\system32\gdi32 c:\windows\system32\winmm/v/sc
del runfile.*
