rem
rem Construct encode
rem

parse encode=encode/nrf
ce encode=encode
parse machine=machine/nrf
ce machine=machine

rem
rem perform link for windows
rem

ln runfile=c:\ip\windows\i80386\libsav\serlib c:\ip\windows\i80386\libsav\strlib c:\ip\windows\i80386\libsav\extlib c:\ip\windows\i80386\libsav\parlib c:\ip\windows\i80386\lib\main machine encode c:\ip\windows\i80386\lib\cap
genpe encode=runfile c:\windows\system32\kernel32 c:\windows\system32\user32 c:\windows\system32\gdi32 c:\windows\system32\winmm/v
del runfile.*
