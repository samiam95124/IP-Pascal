@echo off
rem @echo off
rem
rem Compile a program for use with the serial level library
rem
parse cparse=cparse #u=.\,\ip\windows\i80386\lib\
ce cparse=cparse
parse parser=parser #u=.\,\ip\windows\i80386\lib\
ce parser=parser
parse symbol=symbol #u=.\,\ip\windows\i80386\lib\
ce symbol=symbol
parse scanner=scanner #u=.\,\ip\windows\i80386\lib\
ce scanner=scanner
parse macro=macro #u=.\,\ip\windows\i80386\lib\
ce macro=macro
ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib c:\ip\windows\i80386\lib\parlib c:\ip\windows\i80386\lib\main macro scanner symbol parser cparse c:\ip\windows\i80386\lib\cap
genpe cparse=runfile c:\windows\system32\kernel32 c:\windows\system32\user32 c:\windows\system32\gdi32 c:\windows\system32\winmm/v/sc
del runfile.*
del cparse.int
del cparse.obj
del cparse.sym
