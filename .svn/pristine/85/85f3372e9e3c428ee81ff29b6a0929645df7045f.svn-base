rem
rem Construct encode
rem

parse encode=encode/nrf
parse machine=machine/nrf

encode encode=encode/noc
rem ec encode=encode/noc
encode machine=machine/noc
rem ec machine=machine/noc

rem
rem perform link for windows
rem

ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib c:\pascomp\comlib\parlib c:\ip\windows\i80386\lib\main machine encode c:\ip\windows\i80386\lib\cap /nu
genpe encode=runfile c:\windows\system32\kernel32 c:\windows\system32\user32 c:\windows\system32\gdi32 c:\windows\system32\winmm/v/sc
del runfile.*
