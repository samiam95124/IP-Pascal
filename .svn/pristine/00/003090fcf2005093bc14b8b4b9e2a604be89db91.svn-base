@echo off
rem
rem Compile pretty printer
rem
parse scanner=scanner #u=.,\ip\lib
parse pretty=pretty #u=.,\ip\lib\
ce scanner=scanner
ce pretty=pretty
ln runfile=c:\ip\lib\serlib c:\ip\lib\strlib c:\ip\lib\extlib scanner c:\ip\lib\main pretty c:\ip\lib\cap
genpe pretty=runfile c:\windows\system\kernel32 c:\windows\system\user32 c:\windows\system\gdi32 c:\windows\system\winmm/v/sc
del runfile.*
del pretty.int
del pretty.obj
del pretty.sym
