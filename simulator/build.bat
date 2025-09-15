rem
rem Construct passim
rem

parse passim=passim/nrf
ec passim=passim/noc/nrc/nac/nclcl

rem
rem perform link for windows
rem

rem ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib c:\ip\windows\i80386\lib\parlib c:\ip\windows\i80386\lib\main passim c:\ip\windows\i80386\lib\cap
ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib c:\pascomp\comlib\parlib c:\ip\windows\i80386\lib\main passim c:\ip\windows\i80386\lib\cap
genpe passim=runfile/v/sc
del runfile.*
