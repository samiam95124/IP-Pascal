parse scntst=scntst
ec scntst=scntst
rem ln runfile=conlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib c:\ip\windows\i80386\lib\main scntst cap/nu
ln runfile=gralib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib c:\ip\windows\i80386\lib\main scntst cap/nu
rem ln runfile=trmlib scntst cap
rem genpe scntst=runfile/wg /v
genpe scntst=runfile/sc /v
del runfile.*
