parse gratst=gratst
rem ec gratst=gratst/scxt
ec gratst=gratst
rem ln runfile=gralibx c:\ip\windows\i80386\lib\strlibx c:\ip\windows\i80386\lib\extlibx c:\ip\windows\i80386\lib\main gratst cap/nu
ln runfile=gralib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib c:\ip\windows\i80386\lib\main gratst cap/nu
rem genpe gratst=runfile/wg /v
genpe gratst=runfile/sc /v
del runfile.*
