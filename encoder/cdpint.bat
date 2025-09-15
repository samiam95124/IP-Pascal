rem
rem Construct dpint
rem

parse dpint=dpint/nrf
encode dpint

rem
rem perform link for windows
rem

ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\trnlib c:\ip\windows\i80386\lib\main dpint c:\ip\windows\i80386\lib\cap #ps=$401000 #vs=$419000 #lv #ll #lm > dpint.loc
genpe dpint=runfile c:\windows\system32\kernel32 c:\windows\system32\user32 c:\windows\system32\gdi32 c:\windows\system32\winmm/v/sc
del runfile.*
