@echo off
rem @echo off
rem
rem Compile a program for use with the serial level library
rem
parse ch2ph=ch2ph /u=.\,\ip\windows\i80386\lib\
ec ch2ph=ch2ph/noc/nrc/nac/nclcl
parse parser=parser /u=.\,\ip\windows\i80386\lib\
ec parser=parser/noc/nrc/nac/nclcl
parse symbol=symbol /u=.\,\ip\windows\i80386\lib\
ec symbol=symbol/noc/nrc/nac/nclcl
parse scanner=scanner /u=.\,\ip\windows\i80386\lib\
ec scanner=scanner/noc/nrc/nac/nclcl
parse macro=macro /u=.\,\ip\windows\i80386\lib\
ec macro=macro/noc/nrc/nac/nclcl
ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib c:\ip\windows\i80386\lib\parlib c:\ip\windows\i80386\lib\main macro scanner symbol parser ch2ph c:\ip\windows\i80386\lib\cap/nu
genpe ch2ph=runfile/v/sc
rem genpe ch2ph=runfile c:\windows\system32\kernel32 c:\windows\system32\user32 c:\windows\system32\gdi32 c:\windows\system32\winmm/v/sc
del runfile.*
del ch2ph.int
del ch2ph.obj
del ch2ph.sym
