rem
rem Construct test using new encoder
rem

parse test=test/nrf
ce test=test

rem
rem perform link for windows
rem

ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\main test c:\ip\windows\i80386\lib\cap #ps=$401000 #vs=$419000 #lv #ll #lm > test.loc
genpe test=runfile c:\windows\system32\kernel32 c:\windows\system32\user32 c:\windows\system32\gdi32 c:\windows\system32\winmm/v/sc
del runfile.*
