parse install=install/v/ns/nrf
rem ec install=install/noc
ec install=install/noc/scxt/discm
rem ln temp=c:\ip\windows\i80386\lib\gralib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib c:\ip\windows\i80386\lib\parlib c:\ip\windows\i80386\lib\main install c:\ip\windows\i80386\lib\cap/v/nu
ln temp=c:\ip\windows\i80386\lib\gralibx c:\ip\windows\i80386\lib\strlibx c:\ip\windows\i80386\lib\extlibx c:\ip\windows\i80386\lib\parlibx c:\ip\windows\i80386\lib\main install c:\ip\windows\i80386\lib\cap/v/nu
rem genpe install=temp/sc/v
genpe install=temp/v/wg
del temp.obj
del temp.sym
rem 
rem Create a copy for Windows setup.
rem
copy install.exe setup.exe
