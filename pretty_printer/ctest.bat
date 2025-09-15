@echo off
rem
rem Compile test printer
rem
parse scanner=scanner #u=.,\ip\lib
parse test=test #u=.,\ip\lib\
ce scanner=scanner
ce test=test
ln runfile=c:\ip\lib\serlib c:\ip\lib\strlib c:\ip\lib\extlib scanner c:\ip\lib\main test c:\ip\lib\cap
genpe test=runfile c:\windows\system\kernel32 c:\windows\system\user32 c:\windows\system\gdi32 c:\windows\system\winmm/v/sc
del runfile.*
del test.int
del test.obj
del test.sym
