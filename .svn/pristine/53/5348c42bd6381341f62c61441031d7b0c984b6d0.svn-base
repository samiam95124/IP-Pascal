rem
rem Construct prime using new encoder
rem

parse prime=prime/nrf
rem encode prime=prime/noc/nrc/sls/nac/nclcl
encode prime=prime/noc/nrc/sls/nac/nclcl/nounroll
rem ec prime=prime
rem as prime=prime

rem
rem perform link for windows
rem
                              
ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib c:\ip\windows\i80386\lib\main prime c:\ip\windows\i80386\lib\cap #ps=$401000 #vs=$419000 #lv #ll #lm > prime.loc
genpe prime=runfile c:\windows\system32\kernel32 c:\windows\system32\user32 c:\windows\system32\gdi32 c:\windows\system32\winmm/v/sc
del runfile.*
