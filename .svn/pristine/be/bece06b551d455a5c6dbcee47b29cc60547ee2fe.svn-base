rem
rem Construct extended using new encoder
rem

..\pparse\parse extended=extended/nrf
encode extended=extended/noc

rem
rem perform link for windows
rem

ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\main extended c:\ip\windows\i80386\lib\cap /nu
rem ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\main extended c:\ip\windows\i80386\lib\cap #ps=$401000 #vs=$419000 #lv #ll #lm > extended.loc
genpe extended=runfile c:\windows\system32\kernel32 c:\windows\system32\user32 c:\windows\system32\gdi32 c:\windows\system32\winmm/v/sc
del runfile.*
