parse test1=test1/nrf
rem ec test1=test1/noc
ec test1=test1/noc/scxt

rem ln runfile=serlib c:\ip\windows\i80386\lib\strlib extlib c:\ip\windows\i80386\lib\main test1 c:\ip\windows\i80386\lib\cap/nu
ln runfile=serlibx c:\ip\windows\i80386\lib\strlibx extlibx c:\ip\windows\i80386\lib\main test1 c:\ip\windows\i80386\lib\cap/nu
genpe test1=runfile/sc/v
rem del runfile.*
