rem
rem Construct test1 using new encoder
rem

parse test1=test1/nrf
encode test1/noc
ce test1=test1
as trnlib=trnlib

rem
rem perform link for windows
rem

ln runfile=c:\ip\windows\i80386\lib\serlib trnlib c:\ip\windows\i80386\lib\main test1 c:\ip\windows\i80386\lib\cap #ps=$401000 #vs=$410000 #lv #ll #lm > test1.loc
genpe test1=runfile c:\windows\system32\kernel32 c:\windows\system32\user32 c:\windows\system32\gdi32 c:\windows\system32\winmm/v/sc
del runfile.*
