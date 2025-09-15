parse mantst=mantst
ec mantst=mantst
rem ln runfile=gralib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib c:\ip\windows\i80386\lib\main mantst cap/nu
ln runfile=gralib c:\ip\windows\i80386\lib\main mantst cap/nu
rem genpe mantst=runfile/wg /v
genpe mantst=runfile/sc /v
del runfile.*
