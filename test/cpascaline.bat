..\parser\parse pascaline=pascaline
..\parser\parse pascaline1=pascaline1
..\encoder\encode pascaline=pascaline
..\encoder\encode pascaline1=pascaline1
..\..\assm\i80586\as paslib_equ=paslib_equ
..\..\assm\ln\ln temp=C:\ip\windows\i80386\lib\serlib ..\encoder\maclib paslib_equ pascaline1 c:\ip\windows\i80386\lib\main pascaline C:\ip\windows\i80386\lib\cap/v/nu
..\..\assm\windows\genpe pascaline=temp/v/sc
del temp.obj
del temp.sym
