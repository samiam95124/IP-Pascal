parse test=test/nrf
ec test=test/noc

ln runfile=serlib c:\ip\windows\i80386\lib\main test c:\ip\windows\i80386\lib\cap/nu
genpe test=runfile/sc/v
rem del runfile.*
