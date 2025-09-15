rem
rem Construct test
rem

parse test=test/nrf
ec test=test

rem
rem perform link for windows
rem

rem ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\main test c:\ip\windows\i80386\lib\cap/nu
ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\main test c:\ip\windows\i80386\lib\cap/nu #ps=$401000 #vs=$419000 #lv #ll #lm > test.loc
genpe test=runfile/v/sc
del runfile.*
