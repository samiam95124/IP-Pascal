@echo off
rem
rem Construct standard using new encoder
rem
rem Will take up to five parameters, which are typically options
rem

..\parser\parse iso7185pat=iso7185pat/nrf
rem parse standard=standard/nrf/s
encode iso7185pat=iso7185pat %1 %2 %3 %4 %5

rem
rem perform link for windows
rem
ln runfile=maclib c:\projects\pascomp\windows_platform\serlib c:\ip\windows\i80386\lib\main iso7185pat c:\ip\windows\i80386\lib\cap/nu
rem ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\main standard c:\ip\windows\i80386\lib\cap /nu
rem ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\main standard c:\ip\windows\i80386\lib\cap #ps=$401000 #vs=$419000 #lv #ll #lm > standard.loc
rem genpe standard=runfile c:\windows\system32\kernel32 c:\windows\system32\user32 c:\windows\system32\gdi32 c:\windows\system32\winmm/v/sc
genpe iso7185pat=runfile/v/sc
del runfile.*
