rem
rem Construct test2
rem

parse test2=test2/nrf/nooverflow
ec test2=test2/noc/nrc/nac/nclcl/cxt

rem
rem perform link for windows
rem

ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\main test2 c:\ip\windows\i80386\lib\cap/nu
genpe test2=runfile/v/sc
del runfile.*
