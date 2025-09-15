@echo off
rem
rem Compiler scanner test
rem
parse scanner=scanner #u=.,\ip\lib
parse scan=scan #u=.,\ip\lib\
ce scanner=scanner
ce scan=scan
ln runfile=c:\ip\lib\serlib c:\ip\lib\strlib c:\ip\lib\extlib scanner c:\ip\lib\main scan c:\ip\lib\cap
genpe scan=runfile c:\windows\system\kernel32 c:\windows\system\user32 c:\windows\system\gdi32 c:\windows\system\winmm/v/sc
del runfile.*
del scan.int
del scan.obj
del scan.sym
