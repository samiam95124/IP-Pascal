parse standard=standard #nrf
ec standard=standard
ln runfile=serlib c:\ip\windows\i80386\lib\main standard c:\ip\windows\i80386\lib\cap
genpe standard=runfile c:\windows\system32\kernel32 c:\windows\system32\user32 c:\windows\system32\gdi32 c:\windows\system32\winmm/sc /v
del runfile.*
