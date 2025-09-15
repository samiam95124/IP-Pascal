@echo off
rem
rem Compile pc printer
rem

rem
rem Build the character translation version
rem
copy xltmod_on.pas xltmod.pas
parse scanner=scanner
parse pc=pc
ec scanner=scanner/scxt/discm
ec pc=pc/scxt/discm

rem
rem Build the "plain" charcter version. Use this ONLY for debugging.
rem
rem parse scanner=scanner
rem parse pc=pc
rem copy xltmod_off.pas xltmod.pas
rem ec scanner=scanner
rem ec pc=pc

rem ln runfile=c:\ip\windows\i80386\lib\blotter c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib c:\ip\windows\i80386\lib\parlib scanner c:\ip\windows\i80386\lib\main c:\ip\windows\i80386\lib\reglock c:\ip\windows\i80386\lib\timelock pc c:\ip\windows\i80386\lib\cap/nu
rem ln runfile=c:\ip\windows\i80386\lib\blotter c:\ip\windows\i80386\lib\serlibx c:\ip\windows\i80386\lib\strlibx c:\ip\windows\i80386\lib\extlibx c:\ip\windows\i80386\lib\parlibx scanner c:\ip\windows\i80386\lib\main c:\ip\windows\i80386\lib\reglockx c:\ip\windows\i80386\lib\timelockx pc c:\ip\windows\i80386\lib\cap/nu
ln runfile=c:\ip\windows\i80386\lib\serlibx c:\ip\windows\i80386\lib\strlibx c:\ip\windows\i80386\lib\extlibx c:\ip\windows\i80386\lib\parlibx scanner c:\ip\windows\i80386\lib\main pc c:\ip\windows\i80386\lib\cap/nu
genpe pc=runfile/v
del runfile.*
del pc.int
del pc.obj
del pc.sym
