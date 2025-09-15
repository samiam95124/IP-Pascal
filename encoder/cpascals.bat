rem
rem Construct pascals using new encoder
rem

..\pparse\parse pascals=pascals/nrf/standard
encode pascals=pascals/noc/nrc/nac/nclcl

rem
rem perform link for windows
rem

rem ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\main pascals c:\ip\windows\i80386\lib\cap /nu
ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\main pascals c:\ip\windows\i80386\lib\cap #ps=$401000 #vs=$424000 #lv #ll #lm > pascals.loc
genpe pascals=runfile c:\windows\system32\kernel32 c:\windows\system32\user32 c:\windows\system32\gdi32 c:\windows\system32\winmm/v/sc
del runfile.*
