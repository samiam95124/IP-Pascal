..\parser\parse %1=%1/nrf
..\encoder\encode %1=%1
..\..\assm\i80586\as paslib_equ=paslib_equ
..\..\assm\ln\ln temp=C:\ip\windows\i80386\lib\serlib paslib_equ c:\ip\windows\i80386\lib\main %1 C:\ip\windows\i80386\lib\cap/v/nu
..\..\assm\windows\genpe %1=temp/v/sc
del temp.obj
del temp.sym
