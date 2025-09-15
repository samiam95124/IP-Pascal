parse chkenc=chkenc
ce chkenc=chkenc

rem
rem Windows link
rem

ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib chkenc c:\ip\windows\i80386\lib\cap
genpe ce80386=runfile c:\windows\system32\kernel32 c:\windows\system32\user32 c:\windows\system32\gdi32 c:\windows\system32\winmm/v
del runfile.*

rem
rem Linux link
rem

ln runfile=c:\ip\linux\i80386\lib\serlib c:\ip\linux\i80386\lib\strlib c:\ip\linux\i80386\lib\extlib chkenc c:\ip\linux\i80386\lib\cap
genelf ce80386=runfile/v
del runfile.*
